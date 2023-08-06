setwd("/Users/vmaurer/Documents/PhD/Projects/templateMatchingLibrary/plots/")
packages = c(
  "data.table",
  "ggplot2",
  "stringr",
  "parallel",
  "ggpubr",
  "gridExtra",
  "cowplot"
)
out = suppressPackageStartupMessages(sapply(packages, library, character.only=T))

method_colors = c(Ours = "#A7D9CB", PyTom = "#2188c9", STOPGAP = "#fca349")

timings_tomogram = list.files("../benchmarks/", 
                              full.names = T, recursive = T, pattern = "tomogram_\\d+_\\d+.txt",)
timings_tomogram = gsub(timings_tomogram, pattern = "/+", replacement = "/")
timings_tomogram = timings_tomogram[!grepl(pattern = "-\\d+.txt", timings_tomogram)]
timings = rbindlist(lapply(timings_tomogram, function(trial){
  temp = readLines(trial)
  if (length(temp) == 0){
    return(data.table())
  }
  system_time = temp[grepl(pattern = "Elapsed", temp)]
  ram_usage = temp[length(temp)]
  timing = trimws(gsub(system_time, pattern = ".*):(.*)", replacement = "\\1"))
  if (length(stringr::str_count(timing, ":")) == 0){
    system_time = NA
  }else if(stringr::str_count(timing, ":") == 1){
    # is mm:ss
    system_time = as.numeric(gsub(timing, pattern = "(.*):(.*)", replacement = "\\1")) * 60
    system_time = system_time + as.numeric(gsub(timing, pattern = "(.*):(.*)", replacement = "\\2"))
  }else if(stringr::str_count(timing, ":") == 2){
    # is hh:mm:ss
    system_time = as.numeric(gsub(timing, pattern = "(.*):(.*):(.*)", replacement = "\\1")) * 3600
    system_time = system_time + as.numeric(gsub(timing, pattern = "(.*):(.*):(.*)", replacement = "\\2")) * 60
    system_time = system_time + as.numeric(gsub(timing, pattern = "(.*):(.*):(.*)", replacement = "\\3"))
  }
  ram_usage = as.numeric(ram_usage)/1e3
  method = gsub(trial, pattern = ".*/benchmarks/([a-zA-Z0-9]*)/.*_(\\d+).txt", replacement = "\\1")
  run = as.numeric(
    gsub(trial, pattern = ".*/benchmarks/([a-zA-Z0-9]*)/.*_(\\d+)_(\\d+).txt", replacement = "\\3")
  )
  ncores = as.numeric(
    gsub(trial, pattern = ".*/benchmarks/([a-zA-Z0-9]*)/.*_(\\d+)_(\\d+).txt", replacement = "\\2")
  )
  data.table(
    method = method, system_time = system_time, ram_usage = ram_usage, ncores = ncores, run = run
  )
}))
timings_long = melt(timings, measure.vars = c("system_time", "ram_usage"))
timings_long[, variable := factor(
  variable, levels = c("system_time", "ram_usage"),
  labels = c("Runtime [seconds]", "RAM usage [GB]"))
]
format_labels = function(x){
  h = x %/% 1
  m = as.integer((x - h) * 60)
  ret = sprintf("%02d:%02d", h, m)
}
timings_long[variable == "Runtime [seconds]", value := value / 3600]
breaks = unique(timings_long[variable == "Runtime [seconds]"]$value)
breaks = c(0:(max(timings_long[variable == "Runtime [seconds]"]$value + 1)),
           min(timings_long[variable == "Runtime [seconds]"]$value)
)
timings_mean = timings_long[variable == "Runtime [seconds]"][, mean(value), by = .(method, ncores)]
p1 = ggplot(timings_long[variable == "Runtime [seconds]"],
            aes(x = ncores, y = value, fill = method, group = method))+
  geom_point(size = 2, shape = 21, color = "#000000")+
  geom_line(data = timings_mean, mapping = aes(x = ncores, y = V1, color = method, group = method))+
  theme_bw(base_size = 14)+
  scale_color_manual(name = "Method", values = method_colors)+
  scale_fill_manual(name = "Method", values = method_colors)+
  ylab("Runtime [hh : mm]")+
  xlab("CPU cores")+
  scale_y_continuous(
    # trans = "log1p",
    breaks = breaks,
    labels= format_labels(breaks)
    )+
  scale_x_continuous(breaks = sort(unique(timings_long$ncores)), trans = "log2")+
  theme(legend.position = "bottom")
p1

ram_mean = timings_long[variable == "RAM usage [GB]"][, mean(value), by = .(method, ncores)]
p2 = ggplot(timings_long[variable == "RAM usage [GB]"],
            aes(x = ncores, y = value, color = method, group = method, fill = method))+
  geom_point(size = 2, shape = 21, color = "#000000")+
  geom_line(data = ram_mean, mapping = aes(x = ncores, y = V1, color = method, group = method))+
  theme_bw(base_size = 14)+
  scale_color_manual(name = "Method", values = method_colors)+
  scale_fill_manual(name = "Method", values = method_colors)+
  ylab("RAM usage [GB]")+
  xlab("CPU cores")+
  scale_x_continuous(breaks = sort(unique(timings_long$ncores)), trans = "log2")+
  theme(legend.position = "bottom")
p2

lgd = cowplot::get_legend(p1)
upper = cowplot::plot_grid(plotlist = list(
  p1 + theme(legend.position = "None"), p2+ theme(legend.position = "None")),
  labels = "A")
upperTotal = cowplot::plot_grid(plotlist = list(upper, lgd), rel_heights = c(.9, .1), 
                           nrow = 2, ncol = 1)
upperTotal

ggsave("toolComparisonTomogram.pdf", upperTotal, width = 10, height = 7)
