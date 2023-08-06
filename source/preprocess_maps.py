import yaml

import numpy as np

from dge.Density import Density
from dge.Preprocessor import Preprocessor
from dge.helpers import topleft_pad

if __name__ == "__main__":
    with open("../pipelines/config.yaml", "r") as infile:
        data = yaml.full_load(infile)

    density = Density.from_file("../data/emd_8621.mrc")
    structure = Density.from_structure(
        filename_or_structure="../data/5uz4.cif",
        origin=density.origin,
        sampling_rate=density.sampling_rate,
        shape=density.box_size,
        keep_residues={},
    )
    structure.to_file("../data/structure.mrc")

    blurrer = Preprocessor()
    out = density.empty
    out.data = blurrer.gaussian_blur(template=density.data, sigma=2, apix=1)
    out.to_file("../data/map_blurred.mrc")

    blurrer = Preprocessor()
    out = density.empty
    out.data = blurrer.gaussian_blur(template=structure.data, sigma=2, apix=1)
    out.to_file("../data/structure_blurred.mrc")

    structure = Density.from_structure(
        filename_or_structure="../data/5uz4.cif",
        sampling_rate=density.sampling_rate,
        keep_residues={},
    )

    density.trim(cutoff=data["MAP_CUTOFF"], margin=0)
    fourier_box = np.add(structure.box_size, density.box_size) - 1
    density.data = topleft_pad(density.data, fourier_box)
    density.to_file("../data/emd_8621_padded.mrc")
