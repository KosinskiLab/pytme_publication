setwd("/Users/vmaurer/Documents/PhD/Projects/templateMatchingLibrary/plots.nosync/")
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
N_BREAKS = 8

format_labels = function(x){
  h = x %/% 1
  m = as.integer((x - h) * 60)
  ret = sprintf("%02d:%02d", h, m)
}

method = "tomogram"
plots = lapply(c("tomogram", "fitting"), function(method){
  if (method == "tomogram"){
    method_colors = c(pyTME = "#A7D9CB", PyTom = "#2188c9", STOPGAP = "#fca349")
    file_pattern = "tomogram_\\d+_\\d+(_.?\\d+)?.txt"
  }else{
    method_colors = c(pyTME = "#A7D9CB", Situs = "#9B85C1", PowerFit = "#DAA520")
    file_pattern = "fitting_\\d+_\\d+(_.?\\d+)?.txt"
  }
  
  timings = list.files("../benchmarks/", 
                                full.names = T, recursive = T, pattern = file_pattern)
  timings = gsub(timings, pattern = "/+", replacement = "/")
  timings = rbindlist(lapply(timings, function(trial){
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
    method = gsub(trial, pattern = ".*/benchmarks/([a-zA-Z0-9]*)/.*txt", replacement = "\\1")
    splits = strsplit(basename(trial), "_")[[1]]
    ncores = as.numeric(splits[2])
    run = as.numeric(gsub(pattern = "(\\d+)\\.?(txt)?", replacement = "\\1", splits[3]))
    interpolation = as.numeric(gsub(pattern = "(\\-?\\d+)\\.?(txt)?", replacement = "\\1", splits[4]))
    data.table(
      method = method, system_time = system_time, ram_usage = ram_usage, ncores = ncores, run = run, interpolation = interpolation
    )
  }))
  timings[method != "Ours", interpolation := 0]
  timings[method == "Ours" & interpolation != -1, ncores := NA]
  timings[method == "Ours", method := "pyTME"]
  
  timings = timings[ncores <= 32]
  timings_long = melt(timings, measure.vars = c("system_time", "ram_usage"))
  timings_long[, variable := factor(
    variable, levels = c("system_time", "ram_usage"),
    labels = c("Runtime [seconds]", "RAM usage [GB]"))
  ]

  timings_long[variable == "Runtime [seconds]", value := value / 3600]
  timings_long = timings_long[complete.cases(timings_long)]
  breaks = unique(timings_long[variable == "Runtime [seconds]"]$value)
  breaks = c(0:(max(timings_long[variable == "Runtime [seconds]"]$value + 1)),
             min(timings_long[variable == "Runtime [seconds]"]$value)
  )
  timings_long[, new_group:= paste(method, interpolation, sep = "_")]
  timings_mean = timings_long[variable == "Runtime [seconds]"][, mean(value), by = .(method, ncores)]
  p1 = ggplot(timings_long[variable == "Runtime [seconds]"],
              aes(x = ncores, y = value, fill = method, group = new_group))+
    geom_point(size = 2, shape = 21, color = "#000000", alpha= .7)+
    geom_line(data = timings_mean, mapping = aes(x = ncores, y = V1, color = method, group = method))+
    theme_bw(base_size = 14)+
    scale_color_manual(name = "Method", values = method_colors)+
    scale_fill_manual(name = "Method", values = method_colors)+
    ylab("Runtime [hh:mm]")+
    xlab("CPU cores")+
    scale_y_continuous(
      trans = "log2",
      labels = format_labels,
      n.breaks = N_BREAKS,
      limits = c(
        0.7 * min(timings_long[variable == "Runtime [seconds]"]$value), 
        1.3 * max(timings_long[variable == "Runtime [seconds]"]$value)
      ),
      # breaks = breaks,
      # labels= format_labels(breaks)
      )+
    scale_x_continuous(breaks = sort(unique(timings_long$ncores)), trans = "log2")+
    theme(legend.position = "bottom")
  p1
  
  ram_mean = timings_long[variable == "RAM usage [GB]"][, mean(value), by = .(method, ncores)]
  timings_long$origin = method
  p2 = ggplot(timings_long[variable == "RAM usage [GB]"],
              aes(x = ncores, y = value, color = method, group = method, fill = method))+
    geom_point(size = 2, shape = 21, color = "#000000", alpha = .7)+
    geom_line(data = ram_mean, mapping = aes(x = ncores, y = V1, color = method, group = method))+
    theme_bw(base_size = 14)+
    scale_color_manual(name = "Method", values = method_colors)+
    scale_fill_manual(name = "Method", values = method_colors)+
    ylab("RAM usage [GB]")+
    xlab("CPU cores")+
    scale_x_continuous(breaks = sort(unique(timings_long$ncores)), trans = "log2")+
    scale_y_continuous(n.breaks = N_BREAKS, trans = "log2")+
    
    theme(legend.position = "bottom")
  p2
  
  lgd = cowplot::get_legend(p1)
  upper = cowplot::plot_grid(plotlist = list(
    p1 + theme(legend.position = "None"), p2+ theme(legend.position = "None")))
  upperTotal = cowplot::plot_grid(plotlist = list(upper, lgd), rel_heights = c(.9, .1), 
                             nrow = 2, ncol = 1)
  upperTotal
})

upperTotal = cowplot::plot_grid(plotlist = plots, labels = c("A", "B"), nrow = 2)
upperTotal
ggsave("toolComparisonLinearScale.pdf", upperTotal, width = 10, height = 8)


FONT_SIZE = 18
plots = lapply(c("tomogram", "fitting"), function(method){
  if (method == "tomogram"){
    method_colors = c(pyTME = "#A7D9CB", PyTom = "#2188c9", STOPGAP = "#fca349")
    file_pattern = "tomogram_\\d+_\\d+(_.?\\d+)?.txt"
  }else{
    method_colors = c(pyTME = "#A7D9CB", Situs = "#9B85C1", PowerFit = "#FA8072")
    file_pattern = "fitting_\\d+_\\d+(_.?\\d+)?.txt"
  }
  
  timings = list.files("../benchmarks/", 
                       full.names = T, recursive = T, pattern = file_pattern)
  timings = gsub(timings, pattern = "/+", replacement = "/")
  timings = rbindlist(lapply(timings, function(trial){
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
    method = gsub(trial, pattern = ".*/benchmarks/([a-zA-Z0-9]*)/.*txt", replacement = "\\1")
    splits = strsplit(basename(trial), "_")[[1]]
    ncores = as.numeric(splits[2])
    run = as.numeric(gsub(pattern = "(\\d+)\\.?(txt)?", replacement = "\\1", splits[3]))
    interpolation = as.numeric(gsub(pattern = "(\\-?\\d+)\\.?(txt)?", replacement = "\\1", splits[4]))
    data.table(
      method = method, system_time = system_time, ram_usage = ram_usage, ncores = ncores, run = run, interpolation = interpolation
    )
  }))
  timings[method != "Ours", interpolation := 0]
  timings[method == "Ours" & interpolation != -1, ncores := NA]
  timings[method == "Ours", method := "pyTME"]
  
  timings = timings[method == "Powerfit", method := "PowerFit"]
  
  timings = timings[method != "PyTomModule"]
  timings = timings[ncores <= 32]
  
  timings[, method := factor(method, levels = names(method_colors), labels = names(method_colors))]
  timings_long = melt(timings, measure.vars = c("system_time", "ram_usage"))
  timings_long[, variable := factor(
    variable, levels = c("system_time", "ram_usage"),
    labels = c("Runtime [seconds]", "RAM usage [GB]"))
  ]

  timings_long[variable == "Runtime [seconds]", value := value / 3600]
  timings_long = timings_long[complete.cases(timings_long)]
  breaks = unique(timings_long[variable == "Runtime [seconds]"]$value)
  breaks = c(0:(max(timings_long[variable == "Runtime [seconds]"]$value + 1)),
             min(timings_long[variable == "Runtime [seconds]"]$value)
  )
  timings_long[, new_group:= paste(method, interpolation, sep = "_")]
  timings_mean = timings_long[variable == "Runtime [seconds]"][, mean(value), by = .(method, ncores)]
  
  p1 = ggplot(timings_long[variable == "Runtime [seconds]"],
              aes(x = ncores, y = value, fill = method, group = method))+
    geom_line(data = timings_mean, mapping = aes(x = ncores, y = V1, color = method, group = method),
                                                 linewidth = 2)+
    geom_point(size = 4, shape = 21, color = "#000000", alpha= .7)+
    theme_bw(base_size = FONT_SIZE)+
    scale_color_manual(name = "Tool", values = method_colors)+
    scale_fill_manual(name = "Tool", values = method_colors)+
    ylab("Runtime [hours : minutes]")+
    xlab("CPU cores")+
    scale_y_continuous(
      trans = "log2",
      labels = format_labels,
      n.breaks = N_BREAKS,
      limits = c(
        0.7 * min(timings_long[variable == "Runtime [seconds]"]$value), 
        1.3 * max(timings_long[variable == "Runtime [seconds]"]$value)
      )
    )+
    ggtitle("AMD Epyc 7502 (CPU)")+
    # annotation_logticks(base = 2)+
    scale_x_continuous(
      breaks = sort(unique(timings_long$ncores)), 
      trans = "log2",
      )+
    theme(legend.position = "bottom",
          plot.background = element_rect(fill = "transparent", color = NA),
          plot.title = element_text(size = FONT_SIZE - 2, hjust = .5)
    )
  p1
})

method_colors = c(pyTME = "#A7D9CB", PyTom = "#2188c9", STOPGAP = "#fca349")
# pyTME 27672 rotations, pytom 15192
gpu_timings = data.table(
  method = c("PyTom", "PyTom", "PyTom", "pyTME", "pyTME", "pyTME"),
  value = c(2272.647601, 2253.280556, 2244.871726, 2433.147, 2432.139, 2437.942)
)
gpu_timings[method == "pyTME", value := value * 15192 / 27672]
gpu_timings = gpu_timings[, value := value / 3600]
gpu_timings = gpu_timings[, .(mean_runtime = mean(value), sd_runtime = sd(value)), by = method]
gpu_timings[, ymin := mean_runtime - sd_runtime]
gpu_timings[, ymax := mean_runtime + sd_runtime]

gpu_timings_plot = ggplot(gpu_timings, aes(x = method, y = mean_runtime, fill = method, group = method))+
  geom_col(color = "#000000")+
  geom_linerange(aes(ymin = ymin,  ymax = ymax))+
  theme_bw(base_size = FONT_SIZE)+
  scale_color_manual(name = "Tool", values = method_colors)+
  scale_fill_manual(name = "Tool", values = method_colors)+
  ylab("Runtime [hours : minutes]")+
  xlab("Tool")+
  scale_y_continuous(
    labels = format_labels,
    # n.breaks = N_BREAKS // 2,
    limits = c(0, 1.05 * max(gpu_timings$mean_runtime)),
    breaks = c(0, 15 / 60, 30 / 60, unique(gpu_timings$mean_runtime))
  )+
  ggtitle("NVIDIA A100 (GPU)")+
  theme(legend.position = "bottom",
        plot.background = element_rect(fill = "transparent", color = NA),
        plot.title = element_text(size = FONT_SIZE - 2, hjust = .5)
  )

upperTotal = cowplot::plot_grid(
  plotlist = list(
    plots[[1]], 
    plots[[2]] + theme(axis.title.y = element_text(color = "#FFFFFF")), 
    gpu_timings_plot + theme(axis.title.y = element_text(color = "#FFFFFF"))
  ), 
  labels = c("A", "B", "C"), 
  ncol = 3, 
  label_size = FONT_SIZE
)
upperTotal
ggsave("toolComparison.pdf", upperTotal, width = 12, height = 6)


bin_timings = data.table(
  bin = c(
    1,1,1, 
    2,2,2, 
    4,4,4,
    8,8,8),
  value = c(
    9374.79,9776.52,10557.92,
    1319.74,1329.30,1332.75,
    162.29,163.53,163.74,
    30.56,30.82,32.46
  )
)
bin_timings[, value := value / 3600]
timings_mean = bin_timings[, mean(value), by = .(bin)]
bin_timings_lots = ggplot(bin_timings,aes(x = bin, y = value, fill = "#A7D9CB"))+
    geom_line(data = timings_mean, mapping = aes(x = bin, y = V1), linewidth = 2, color = "#A7D9CB")+
    geom_point(size = 4, shape = 21, color = "#000000", alpha= .7, fill = "#A7D9CB")+
    theme_bw(base_size = FONT_SIZE)+
    scale_color_manual(name = "Tool", values = method_colors)+
    scale_fill_manual(name = "Tool", values = method_colors)+
    ylab("Runtime [hours : minutes]")+
    xlab("Binning")+
    scale_y_continuous(
      trans = "log10",
      labels = format_labels,
      # n.breaks = N_BREAKS,
      breaks = sort(unique(timings_mean$V1)),
      limits = c(
        1 * min(bin_timings$value), 
        1.3 * max(bin_timings$value)
      )
    )+
    annotation_logticks(base = 10)+
    scale_x_continuous(
      breaks = sort(unique(bin_timings$bin)), 
      trans = "log2",
      )+
    theme(legend.position = "bottom",
          plot.background = element_rect(fill = "transparent", color = NA),
          panel.background = element_blank()
    )
bin_timings_lots
ggsave("bin_timings.pdf", bin_timings_lots, width = 8, height = 6, bg = "transparent")
