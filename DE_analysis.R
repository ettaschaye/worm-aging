library(monocle3)
library(dplyr)

d1cds <- load_mm_data(mat_path = "~/Desktop/Qbb_project_data/day1/matrix.mtx", 
                      feature_anno_path = "~/Desktop/Qbb_project_data/day1/features.tsv", 
                      cell_anno_path = "~/Desktop/Qbb_project_data/day1/barcodes.tsv")

d11cds <- load_mm_data(mat_path = "~/Desktop/Qbb_project_data/day11/matrix.mtx", 
                      feature_anno_path = "~/Desktop/Qbb_project_data/day11/features.tsv", 
                      cell_anno_path = "~/Desktop/Qbb_project_data/day11/barcodes.tsv")

d8cds <- load_mm_data(mat_path = "~/Desktop/Qbb_project_data/day8/matrix.mtx", 
                      feature_anno_path = "~/Desktop/Qbb_project_data/day8/features.tsv", 
                      cell_anno_path = "~/Desktop/Qbb_project_data/day8/barcodes.tsv")

d15cds <- load_mm_data(mat_path = "~/Desktop/Qbb_project_data/day15/matrix.mtx", 
                      feature_anno_path = "~/Desktop/Qbb_project_data/day15/features.tsv", 
                      cell_anno_path = "~/Desktop/Qbb_project_data/day15/barcodes.tsv")



cds_combined <- combine_cds(list(d1cds, d8cds))
#combine cell data sets 

cds <- preprocess_cds(cds_combined, num_dim = 100)
#normalized with PCA (100 PCs)

plot_pc_variance_explained(cds)
#Shows that 100 PCs explain most of the variance in the data set

cds <- reduce_dimension(cds)

plot_cells(cds)
#Reduce dimensionality and plot with UMAP 


colData(cds) #Shows how the cells are annotated by the authors (Sample 1 is Day1, sample 2 is Day15)
#Day1 has 11000 cells, Day15 has 888 cells. Datasets are combined into a single cds. 
length(colData(cds)$sample[colData(cds)$sample == 2])

plot_cells(cds, color_cells_by = "sample") #Shows there is significant differences in gene expression between Day1 and Day15 (but maybe this could be because there are so many less cells in Day15?)
# Just from eyeballing it, it looks like there are certain cell types that are overepresented in the D15 data set (and many that are underepresented)
# I don't think this is a batch effect we should control for, as we do expect to see expression variation between these timepoints 
# I think we should find another timepoint that more closely matches the clusters seen in Day1. 

#Now that I have switched to Day11, cluster representation is better but not great. 
# Day 8 a little better. 10,000 (day1) vs 7,890 (day8) cells. 

#control for batch effects (day1 vs day8)
cds <- align_cds(cds, num_dim = 100, alignment_group = "sample")
cds <- reduce_dimension(cds)
plot_cells(cds, color_cells_by="sample", label_cell_groups=FALSE)
#when controlling for batch effects, Day1 and Day8 look really good! You could do a lot with a DE analysis between timepoints with this I think. 

cds <- cluster_cells(cds, resolution=1e-5)
plot_cells(cds)
