
#---------------------------------#

rm(list = ls())
require(tidyverse)
require(igraph)
require(ggraph)

df_profes <- read_csv(file.choose())
df_invest <- read_csv(file.choose())
df_docencia <- read_csv(file.choose())
df_pubs <- read_csv(file.choose())

# Que porcentaje de investigaciones tienen colaborador?
profes_x_investigacion <- distinct(df_invest, titulo, ident) %>%
  group_by(titulo) %>%
  summarise(n_profes = n())

sum ( table(profes_x_investigacion$n_profes) [2:7] )  / sum (table(profes_x_investigacion$n_profes))

# Cuantas investigaciones tienen colaboradores 
# entre departamentos academicos? Y entre secciones?

colaboraciones <- df_profes %>%
  inner_join(df_invest, by = "ident") %>%
  select(ident, titulo, "dep_academico1" = dep_academico, "seccion1" = seccion, coinvestigador_pucp) %>%
  distinct(ident, titulo, dep_academico1, seccion1, coinvestigador_pucp) %>%
  inner_join(   filter(profes_x_investigacion, n_profes > 1 ),
                by = "titulo") %>%                     # hasta aqui hay el numero esperado, con el siguiente join se reducira
  inner_join(df_profes, by = c("coinvestigador_pucp" = "ident") ) %>% 
  select(ident, titulo, dep_academico1, seccion1, coinvestigador_pucp, 
         "dep_academico2" = dep_academico, "seccion2" = seccion)

# sanity checck, su dimension debe ser igual a sum ( table(profes_x_investigacion$n_profes) [2:7] )

inter_dep <- filter(colaboraciones, as.character(dep_academico1) != as.character(dep_academico2) )  
dim( distinct(inter_dep, titulo))

inter_sec <- filter(colaboraciones, as.character(seccion1) != as.character(seccion2) )  
dim( distinct(inter_sec, titulo))

#---------------------------------#
# CREACI�N ESTRUCTURA DE GRAFO #

# Creando objeto igraph para alimentar ggraph
# Ver Network Visualisation with R - Katherine Ognyanova
dep_links <- inter_dep %>% select("id_source" = ident,
                                  "id_target" = coinvestigador_pucp )

dep_vertices <- rbind( select(inter_dep, "id_vertice" = ident, "dep_academico" = dep_academico1),
                       select(inter_dep, "id_vertice" = coinvestigador_pucp, "dep_academico" = dep_academico2)
) %>% distinct()

# Crear objeto igraph
dep_graph <- graph_from_data_frame(d = dep_links, vertices = dep_vertices, directed = F)

# Calcular algunas medidas de centralidad 
dep_vertices$betweenness <- betweenness(dep_graph, directed = FALSE)   
dep_vertices$grados <- degree(dep_graph, mode = "all") 
dep_vertices$nombre <- dep_vertices$id_vertice

dep_graph <- graph_from_data_frame(d = dep_links, vertices = dep_vertices, directed = F)


# Para secciones
sec_links <- inter_sec %>% select("id_source" = ident,
                                  "id_target" = coinvestigador_pucp,
                                  "label" = titulo)

sec_vertices <- rbind( select(inter_sec, "id_vertice" = ident, "seccion" = seccion1),
                       select(inter_sec, "id_vertice" = coinvestigador_pucp, "seccion" = seccion2)
) %>%
  mutate(seccion = sub("Seccion ", "", seccion) ) %>%
  mutate(seccion = sub("Ingenieria ", "", seccion) ) %>%
  mutate(seccion = sub("de ", "", seccion) ) %>%
  distinct()

# Crear objeto igraph
sec_graph <- graph_from_data_frame(d = sec_links, vertices = sec_vertices, directed = F)
sec_vertices$betweenness <- betweenness(sec_graph, directed = FALSE)   
sec_vertices$grados <- degree(sec_graph, mode = "all") 
sec_vertices$nombre <- sec_vertices$id_vertice
sec_graph <- graph_from_data_frame(d = sec_links, vertices = sec_vertices, directed = F)

#---------------------------------#
# VISUALIZACION DE LAS REDES #

set.seed(3)
ggraph(dep_graph, 'fr') + 
  labs(title = "Red de colaboracion interdepartamentos en investigaciones PUCP", 
       color="Departamento Academico") + 
  geom_edge_link2(   edge_colour = "black") +   # aes(label = label), desastre!
  geom_node_point( aes(color = dep_academico, size = betweenness) ) +
  geom_node_text( aes(label = ifelse(betweenness > 120, as.character(nombre), NA)  )  ) +
  theme_graph()  + 
  scale_size(guide = "none")  


set.seed(10)

ggraph(sec_graph, 'fr') +
  labs(title = "Red de colaboración intersecciones en investigaciones PUCP",
       color="Departamento Académico") +
  geom_edge_link2(   edge_colour = "black") +   # aes(label = label), desastre!
  geom_node_point( aes(color = seccion, size = betweenness) )  +
  geom_node_text( aes(label = ifelse(betweenness > 2500, as.character(nombre), NA)  ) ) +
  theme_graph()  +
  scale_size(guide = "none")   +
  scale_color_discrete(guide = "none")


# Separando la leyenda porque ocupaba demasiado espacio
grafico <-  ggraph(sec_graph, 'fr') +
  labs(title = "Red de colaboracion intersecciones en investigaciones PUCP",
       color="Departamento Academico") +
  geom_edge_link2(   edge_colour = "black") +   # aes(label = label), desastre!
  geom_node_point( aes(color = seccion, size = betweenness) )  +
  geom_node_text( aes(label = ifelse(betweenness > 2500, as.character(nombre), NA)  ) ) +
  theme_graph()  +
  scale_size(guide = "none")


gros <- ggplot_gtable(ggplot_build(grafico))$grobs
plot(gros[[15]])
