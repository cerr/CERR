# Main function to run segmentation of pharyngeal constrictor muscle
# Aditi Iyer
# iyera@mskcc.org
# Jan 2, 2020

import modules.structures.fuse_seg_cm


def main():
    # Segment larynx
    modules.structures.fuse_seg_cm.main(1)


main()
