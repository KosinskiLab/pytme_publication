from dge.Density import Density
from dge.Preprocessor import Preprocessor

if __name__ == "__main__":
    density = Density.from_file("../data/emd_8621.mrc")
    structure = Density.from_structure(
        filename_or_structure = "../data/5uz4.cif",
        origin = density.origin,
        sampling_rate = density.sampling_rate,
        shape = density.box_size
    )
    structure.to_file("../data/structure.mrc")

    blurrer = Preprocessor()
    out = density.empty
    out.data = blurrer.gaussian_blur(
        template = density.data,
        sigma = 2,
        apix = 1
    )
    out.to_file("../data/map_blurred.mrc")

    blurrer = Preprocessor()
    out = density.empty
    out.data = blurrer.gaussian_blur(
        template = structure.data,
        sigma = 2,
        apix = 1
     )
    out.to_file("../data/structure_blurred.mrc")
