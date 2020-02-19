# Main function to run segmentation of larynx
# Aditi Iyer
# iyera@mskcc.org
# Jan 2, 2020

import modules.structures.fuse_seg_larynx


def main():
    # Segment larynx
    modules.structures.fuse_seg_larynx.main(1)


main()
