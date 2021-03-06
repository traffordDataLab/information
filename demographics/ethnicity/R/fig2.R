## Ethnicity: multivariate dot density map of self-reported ethnic groups in Trafford

# load R packages  ---------------------------
library(tidyverse) ; library(sf) ; library(svglite)

# load Lab's ggplot2 theme  ---------------------------
source("https://github.com/traffordDataLab/assets/raw/master/theme/ggplot2/theme_lab.R")

# load data  ---------------------------
# source: https://www.nomisweb.co.uk/census/2011/ks201ew
df <- read_csv("http://www.nomisweb.co.uk/api/v01/dataset/NM_608_1.data.csv?date=latest&geography=1254126722...1254127431,1254260803...1254260823&rural_urban=0&cell=100,200,300,400,500&measures=20100&select=date_name,geography_name,geography_code,rural_urban_name,cell_name,measures_name,obs_value,obs_status_name")

# load geospatial data ---------------------------
sf_oa <- st_read("https://github.com/traffordDataLab/spatial_data/raw/master/oa/2011/trafford_oa_generalised.geojson") # output areas
sf_la <- st_read("https://github.com/traffordDataLab/spatial_data/raw/master/local_authority/2016/trafford_local_authority_generalised.geojson") # wards
sf_tc <- st_read("https://github.com/traffordDataLab/spatial_data/raw/master/town_centres/trafford_town_centres.geojson") # town centres

# manipulate data ---------------------------
df_tidy <- df %>%
  select(area_code = GEOGRAPHY_CODE, area_name = GEOGRAPHY_NAME, group = CELL_NAME, n = OBS_VALUE) %>% 
  spread(group, n) %>% 
  rename(Asian = `Asian/Asian British`,
         Black = `Black/African/Caribbean/Black British`, 
         Mixed = `Mixed/multiple ethnic groups`, 
         Other = `Other ethnic group`)

# merge output areas and ethnicity data
sf_df <- merge(sf_oa, df_tidy, by = "area_code", sort = FALSE)

# create a dataframe with dots for each output area 
dots <- select(as.data.frame(sf_df), White, Asian:Other) / 10 # each dot represents 10 residents

# randomly scatter dots within each corresponding output area
random_dots <- map(names(dots), 
              ~st_sample(sf_df, 
                         size = as.integer(dots[,.]), 
                         type = "random"))

# extract coordinates of each dot
coords <- map(random_dots, ~as.data.frame(do.call(rbind, st_geometry(.))) %>% 
             select(x = lon, y = lat))

# add an ethnicity variable, bind dataframes and set factor levels
ethnicities <- c("White", "Asian", "Black", "Mixed", "Other") # ensures White ethnicity doesn't mask others
plot_dots <- map2_df(coords, ethnicities, ~ mutate(.x, ethnic_group = .y)) %>% 
  mutate(ethnic_group = factor(ethnic_group, levels = ethnicities))

# plot data ---------------------------
# create a palette (source: Cable 2013)
pal <- c("Asian" = "#FF0000", "Black" = "#55FF00", "Mixed" = "#FFAA01", "Other" = "#8A5B47", "White" = "#82B3FF")
plot_dots$ethnic_group <- factor(plot_dots$ethnic_group, levels=c("Asian", "Black", "Mixed", "Other", "White"))

ggplot() +
  geom_sf(data = sf_la, colour = "#d3d3d3", fill = NA, size = 0.3) +
  geom_point(data = plot_dots, aes(x, y, colour = ethnic_group), size = 0.1, alpha = 0.5) +
  geom_label(data = sf_tc, aes(x = lon, y = lat, label = as.character(name)),
             label.size = 0, label.padding = unit(0.1, "lines"), alpha = 0.5,
             size = 2.5, color = "#212121") +
  scale_colour_manual(values = pal) +
  labs(x = NULL, y = NULL, 
       caption = "Source: Census 2011  |  @traffordDataLab",
       colour = NULL) +
  guides(colour = guide_legend(override.aes = list(size = 2))) +
  theme_lab() +
  theme(axis.line = element_blank(), 
        axis.text = element_blank(),
        legend.text = element_text(size = 10, colour = "#757575"),
        legend.position = "bottom",
        plot.title = element_text(face = "bold"))

# save plot / data  ---------------------------
ggsave(file = "output/figures/fig2.svg", width = 10, height = 8)
ggsave(file = "output/figures/fig2.png", width = 10, height = 8)
