librarian::shelf(shiny, ggplot2, dplyr, sf, maptiles, raster, tidyterra, ggspatial, lubridate, tidyr,here,gstat,sp,automap,stars)


batiments <- st_read("batiments/batiments.geojson")
batiments=st_transform(batiments,3857)


filtered_data=function(Y,min_doy,max_doy,min_HH,max_HH){
  temp %>%
    filter(YYYY %in% Y,
           doy >= min_doy, doy <= max_doy,
           HH >= min_HH, HH <= max_HH)
}



interpolation=function(Y,min_doy,max_doy,min_HH,max_HH,contours=FALSE){
  p=NULL
  df=filtered_data(Y,min_doy,max_doy,min_HH,max_HH)
  if(nrow(df) == 0) return(NULL)
  
  df_temp=filtered_data(Y,min_doy,max_doy,0,23)
  temp_range=c(min(df_temp$temperature),max(df_temp$temperature))
  
  df = st_transform(df, 2154)
  df=df %>% dplyr::select(temperature,geometry)
  df_reduce=df %>%
    group_by(geometry) %>%
    summarise(temperature=mean(temperature))
  
  # Grille d'interpolation
  bbox=st_bbox(df)
  grid=st_make_grid(st_as_sfc(bbox),cellsize=1,what="centers")
  grid=st_sf(geometry=grid)
  
  # Variogramme
  v=variogram(temperature~1,df)
  v_mod_ok <- fit.variogram(v, model=vgm(model="Sph"))
  #print(plot(v))
  #print(plot(v,v_mod_ok))

  g=gstat(formula=temperature~1,model=v_mod_ok,data=df_reduce)
  z=predict(g,newdata=grid)
  
  #rmse=sqrt(mean((df$temperature-z$var1.pred)^2))
  #print(paste0("RMSE :",rmse))
  
  # Rasterisation
  template=st_as_stars(st_bbox(df),dx=1,dy=1)
  z_rast=st_rasterize(z["var1.pred"],template=template)
  
  # bbox interpolation
  z_df=as.data.frame(z_rast)
  z_df=z_df[!is.na(z_df$var1.pred), ]
  z_sf=st_as_sf(z_df,coords=c("x","y"),crs=st_crs(df))
  interp_bbox=st_bbox(z_sf)
  
  # Fond de carte
  tiles=get_tiles(df,crop=TRUE)
  
  #DÉCOUPE DES BÂTIMENTS À LA ZONE INTERPOLÉE
  interp_poly=st_as_sfc(interp_bbox)
  st_crs(interp_poly)=st_crs(df)
  batiments <- st_transform(batiments, st_crs(df))
  batiments_clip=st_intersection(batiments,interp_poly)
  

  # Construction du ggplot
  p=ggplot()+
    geom_spatraster_rgb(data=tiles,alpha=1) +
    geom_stars(data=z_rast,aes(fill=var1.pred),alpha=1)
  
  # Ajouter les contours si demandé
  if(contours){
    p=p+geom_contour(
      data=z_df,
      aes(x=x,y=y,z=var1.pred),
      color="black",size=0.3
    )
  }
  
  # Ajouter bâtiments
  p=p+
    geom_sf(data=batiments_clip,color="grey30",fill="grey80",size=0.3,alpha=1)+
    geom_sf(data=df,aes(fill=temperature),shape=21,color="black",
            size=5,stroke=0.5)+
    scale_fill_viridis_c(option="turbo",name="Température (°C)",limits=temp_range)+
    theme_minimal()+
    labs(
      title="Interpolation spatiale des températures (OK)",
      x="Longitude (m)",y ="Latitude (m)"
    ) +
    coord_sf(
      xlim=c(interp_bbox["xmin"],interp_bbox["xmax"]),
      ylim=c(interp_bbox["ymin"],interp_bbox["ymax"])
    )
  
  
  chemin="../data/images"
  nom_fichier=sprintf("%s/interpolation_%d_doy%d_HH%d-%d.png",chemin,Y,min_doy,min_HH,max_HH)
  ggsave(nom_fichier,p,width=10,height=8,dpi=300)
  
  #return(p)
}



## Fonction pour créer les cartes dans un dossier data/images ##
## chaque carte représente une interpolation de la température moyenne de chaque capteur dans un intervalle de 4h ##

verif=function(){
  if (!dir.exists("../data/images")) {
    dir.create("../data/images")
  }
  
  for (i in 2024:2025){
    for (j in 1:366){
      for (z in 1:6)
        if (file.exists(sprintf("%s/interpolation_%d_doy%d_HH%d-%d.png","../data/images",i,j,4*(z-1),4*z-1))){
        }
      else {
        interpolation(i,j,j,4*(z-1),4*z-1)
      }
    }
  }
}