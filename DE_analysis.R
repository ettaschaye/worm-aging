library(monocle3)
library(dplyr)
library(ggplot2)
library(UpSetR)

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

plot_cells(cds) #Shows there is significant differences in gene expression between Day1 and Day15 (but maybe this could be because there are so many less cells in Day15?)
# Just from eyeballing it, it looks like there are certain cell types that are overepresented in the D15 data set (and many that are underepresented)
# I don't think this is a batch effect we should control for, as we do expect to see expression variation between these timepoints 
# I think we should find another timepoint that more closely matches the clusters seen in Day1. 

#Now that I have switched to Day11, cluster representation is better but not great. 
# Day 8 a little better. 10,000 (day1) vs 7,890 (day8) cells. 

#control for batch effects (day1 vs day8)
cds <- align_cds(cds, num_dim = 100, alignment_group = "sample")
cds <- reduce_dimension(cds)


  
#when controlling for batch effects, Day1 and Day8 look really good! You could do a lot with a DE analysis between timepoints with this I think. 
#clusters of interest (seem to have different shapes depending on age: 
# 5, 7, 3


cds <- cluster_cells(cds, resolution=1e-5)
plot_cells(cds)
plot_cells(cds, color_cells_by="cluster", group_cells_by="cluster")
colData(cds)$cluster <- as.character(clusters(cds))
colData(cds)$Timepoint <- as.character(colData(cds)$sample)

plot_cells(cds, color_cells_by="Timepoint", label_cell_groups=FALSE) + 
  scale_color_manual(name = "Timepoint",
                     values=c("#e41a1c", "#377eb8"),
                     labels=c("Day 1", "Day 8"))

#Finding markers per cluster
marker_test_res <- top_markers(cds, group_cells_by="cluster", 
                               reference_cells=1000, cores=8)

marker_test_res %>%
  filter(cell_group == 5) %>%
  arrange(desc(mean_expression)) %>%
  View()

#cluster 5 #Likely Neurons, head neurons, sheath cells 
#WBGene00003754 - head neuron, lateral ganglion 
#WBGene00001758 - anal depressor muscle, amphid neuron, head, head neuron, hypodermis, intestine, nervous system, phasmid neuron, tail, tail neuron, 
#WBGene00004122 - pharyngeal muscle cell, intestinal valve vpi cells
#WBGene00019289 - Neuronal sheath cell, phasmid sheath cell, socket cell, tail, head, amphid sheath cell

marker_test_res %>%
  filter(cell_group == 7) %>%
  arrange(desc(mean_expression)) %>%
  View()

#cluster 7 Definitely hypodermis/seam cells
#WBGene00003891 coelomocyte, hypodermis, seam cell, spermatheca, uterus
#WBGene00001694 anterior arcade cell, vulB1/B2, vulD, hypodermis, neuron, epithelium, seam cell, 
#WBGene00001692 hypodermis, seam cell, 
#WBGene00003765 head neuron, hypodermis, spermatheca, ASIL/R, 
#WBGene00003767 Syncytium, hypodermis, 
#WBGene00001699 seam cell, 
#WBGene00000558 hypodermis, intestine, seam cell, 
#WBGene00011522 seam cell, vulva, cuticle, 
#WBGene00008205 dorsal nerve cord, ventral nerve cord, 
#WBGene00003664 seam cell, 
#WBGene00009342 syncytium, seam cell, permatheca
#WBGene00011583 seam cell, 


marker_test_res %>%
  filter(cell_group == 3) %>%
  arrange(desc(mean_expression)) %>%
  View()

#Cluster 3 #Other neurons 
#WBGene00003759 tail neuron, VA neuron, VB neuron, AFDL/R, AS neurons, body wall musculature, DA neuron, DB neuron, dorsal nerve cord, head neuron, neuron, pharyngeal neuron, 
#WBGene00003747 ventral nerve cord, ASIL/R, AWBL/R, head neuron, spermatheca, tail neuron, VA neuron, ventral cord neuron, vulval muscle, 
#WBGene00008610 VA neuron, VB neuron, VD neuron, DA neuron, DB neuron, 
#WBGene00006999 muscle cell, neuron, reproductive system, spermatheca, vulva, vulval muscle, anal sphincter muscle
#WBGene00006633 tail neuron, ventral cord neuron, touch receptor neuron, DA neuron, 
#WBGene00009958 DD neuron, dorsal nerve cord, GABAergic neuron, IL1 neuron, IL2 neuron, motor neuron, nerve ring, neuron, ventral nerve cord, ventral nerve cord, AIZL/R, ASGL/R, AVHL/R, AVKL/R, OLLL/R, RIAL/R, RICL/R, RMED, RMEL/R, RMEV, SABD, SABVL/R, cholinergic neuron, 
#WBGene00004933 nervous system, rectal gland cell, somatic gonad, 
#WBGene00011251 ventral cord neuron, ventral nerve cord, lateral nerve cord,
#WBGene00009221 neuron, pharyngeal muscle cell
#WBGene00006682 ventral cord neuron, DD neuron, motor neuron, neuron, 
#WBGene00022530 cholinergic neuron, 
#WBGene00010060 AIYL, AIYR


#subset cluster 5
cds_cl5 <- cds[,colData(cds)$cluster == 5]
plot_cells(cds_cl5, color_cells_by = "Timepoint")
#DE analysis based on age
#Normalized_effect is equal to log2FC
gene_fits <- fit_models(cds_cl5, model_formula_str = "~Timepoint")
fit_coefs <- coefficient_table(gene_fits)
cl5dat <- fit_coefs %>%
  filter(q_value != 0) %>%
  filter(normalized_effect != 0 ) %>%
  arrange(q_value) %>%
  filter(q_value < 0.05) 
#Should be able to make a volcano plot with this pretty easily 
ggplot(data = cl5dat, mapping = aes(x = normalized_effect, y = -log10(p_value))) + 
  geom_point() +
  geom_point(aes(color = (abs(normalized_effect) > 2 & p_value < 1e-20))) +
  geom_text(data = cl5dat %>% filter(abs(normalized_effect) > 2 & p_value < 1e-20),
            aes(x = normalized_effect, y = -log10(p_value) + 3, label = V2), size = 2,) +
  theme_classic() +
  theme(legend.position = "none") +
  scale_color_manual(values = c("darkgray", "darkblue")) +
  labs(title = "Head/tail neurons", y = expression(-log[10]("p-value")), x = expression(log[2]("fold change")))



#Do the same for cluster 7
cds_cl7 <- cds[,colData(cds)$cluster == 7]
plot_cells(cds_cl7, color_cells_by = "Timepoint")
#DE analysis
#Normalized_effect is equal to log2FC
gene_fits <- fit_models(cds_cl7, model_formula_str = "~Timepoint")
fit_coefs <- coefficient_table(gene_fits)
cl7dat <- fit_coefs %>%
  filter(q_value != 0) %>%
  filter(normalized_effect != 0 ) %>%
  arrange(q_value) %>%
  filter(q_value < 0.05) 
#Should be able to make a volcano plot with this pretty easily 
ggplot(data = cl7dat, mapping = aes(x = normalized_effect, y = -log10(p_value))) + 
  geom_point() +
  geom_point(aes(color = (abs(normalized_effect) > 2 & p_value < 1e-20))) +
  geom_text(data = cl7dat %>% filter(abs(normalized_effect) > 2 & -log10(p_value) > 150),
           aes(x = normalized_effect, y = -log10(p_value) + 5, label = V2), size = 2,) +
  theme_classic() +
  theme(legend.position = "none") +
  scale_color_manual(values = c("darkgray", "darkblue")) +
  labs(title = "Seam cells", y = expression(-log[10]("p-value")), x = expression(log[2]("fold change")))


#And cluster 3
cds_cl3 <- cds[,colData(cds)$cluster == 3]
plot_cells(cds_cl3, color_cells_by = "Timepoint")
#DE analysis
#Normalized_effect is equal to log2FC
gene_fits <- fit_models(cds_cl3, model_formula_str = "~Timepoint")
fit_coefs <- coefficient_table(gene_fits)
cl3dat <- fit_coefs %>%
  filter(q_value != 0) %>%
  filter(normalized_effect != 0 ) %>%
  arrange(q_value) %>%
  filter(q_value < 0.05) 
#Should be able to make a volcano plot with this pretty easily 
ggplot(data = cl3dat, mapping = aes(x = normalized_effect, y = -log10(p_value))) + 
  geom_point() +
  geom_point(aes(color = (abs(normalized_effect) > 2 & p_value < 1e-20))) +
  geom_text(data = cl3dat %>% filter(abs(normalized_effect) > 2 & p_value < 1e-20),
            aes(x = normalized_effect, y = -log10(p_value) + 3, label = V2), size = 2,) +
  theme_classic() +
  theme(legend.position = "none") +
  scale_color_manual(values = c("darkgray", "darkblue")) +
  labs(title = "Ventral Nerve Cord Neurons", y = expression(-log[10]("p-value")), x = expression(log[2]("fold change")))

cl5dat$V2
cl3dat$V2
cl7dat$V2


  
