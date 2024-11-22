## 11/22 Check In 

##Addressing prior feedback: 

Since the last check in, we were able to address a few issues. We switched from comparing day1/day15 to day1/day8, as day 8 has 7,890 cells, much closer to the 10,000 from day 1. When plotting UMAP and controlling for batch effects (`images/UMAP_day1_day8.png`), we can see that there is good tissue type representation within these two timepoints.

Since we are using a different clustering algorithm than the original paper (Monocle3), we cannot be sure that our clusters correspond to the same tissues as the cluster annotations given in the paper. Do address this, we decided to search for marker genes within our clusters of interest, and assign tissue types based on this. Based on our UMAP of Day 1 vs Day 8 and `images/UMAP_clusters.png`, clusters 3, 5, and 7 seem to have some level of expression variation between the two time points. Thus, we decided to focus on these clusters going forward. 

To assign tissue types to these clusters, we used Monocle `top_markers()` as seen in `DE_analysis.R` to identify markers genes associated with these clusters. Once these genes were identified, we went to the supplemental data from the paper. This data included a list of marker genes associated with each worm tissue type. Cross referencing this list allowed us to identify tissues that associated with the marker genes from our clusters. Many different tissue marker genes were found in each cluster, but clusters 3 and 5 contained marker genes predominantly associated with neurons (head/tail neurons and Ventral Nerve Cord neurons respectively), and cluster 7 contained marker genes predominantly associated with Seam cells. Thus, we annotated these three clusters in this fashion. 

##New progress since last submission 

Now that we have tissue types assigned to clusters of interest 3, 5, and 7, we were able to perform differential expression within each of these clusters using `fit_models()`. Once this differential expression was calculated, we were able to make a volcano plot measuring `log2FC` and `-log10(p_value)` for each cluster. These plots are included in `/images`. 

##Project organization

UMAP plots and volcano plots are contained in `/images`. DE analysis was done in `DE_analysis.R`. 

##Struggles/Questions: 

I think our final original goal was to make an upset plot looking at differentially expressed genes that are shared/unique between the three identified tissue types. This shouldn't be too difficult. In the future, we may want to refine our tissue type annotatons (there were equal number of marker genes for head neurons and tail neurons in cluster 5. Potentially, some of these marker genes could be stronger than others, based on a q value. I think we could find which marker genes are more significant and annotate either head or tail neurons with this in mind.)

Also, in the future, we could potentially do a GO search on the differentially regulated genes within each cluster (and those that are shared between clusters) to better understand the mechanisms behind worm aging. Also, we could potentially look at other timepoints in-between day 1 and 8. 