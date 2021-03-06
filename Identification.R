samplename<-"20180821_Demo"
rawdata<-paste(samplename, ".csv", sep = "")
wd<-paste("C:/Users/nkummer1/switchdrive/MA/Vion/Data Treatment/R/",samplename, sep = "")
setwd(wd)

# Création data.frame, ouverture du fichier csv (avec en moins avant l'importation juste la colonne neutral masses  ((qui est pas toujours complète)))

data1 <- data.frame(read.csv(rawdata,skip=2,sep=";"), headings=TRUE) ## On enlève les deux première ligne
data1<-data1[order(data1$Retention.time..min.),]      # Classement de la plus petite à la plus grande valeur (RT) ...
data1<-as.data.frame(data1[,c(1:ncol(data1)-1)])      # et effacement de la dernière colonne "heading"

#Regroupement des peacks proches (isotopes et autre petite peaks liés à un composé) + création d'un nouveau fichier avec une colonne pour faire des groupe
data2 <- as.data.frame(data1[,])                # On copie le data.frame e
data2$Groupe <- 0                               # On ajout une colonne "Groupe" dans le data.frame
column_groupe<-ncol(as.data.frame(data2))       # On crée la variable column_group, qui correspnd à la position de la colonne dans le sata.frame (dernière colonne)
data2[1,column_groupe]<-1                       # le premier peak est le groupe 1 
n <- nrow(as.data.frame(data1))                 # On cherche le nombre de ligne du data.frame
groupecount<-1                                  # Pour savoir ou on en est dans le nombre de groupe...

# On fixe la valeur mass, RT, CCS et N° de groupe de chaque pic détecté (boucle) = i  ... et on compare avec les peaks suivants et en fonction on donne un no de groupe à chaques pics....
for (i in 1:n){ 
   
    mass<-data2[i,2]
    RT<-data2[i,4]
    CCS<-data2[i,5]
    groupe<-data2[i,column_groupe]
                       
    j<-i+1
    
    #Si le pics J (celui a comparer) n'a pas encore d'appartenance à un groupe, on fait la compariaosn, si non pas. 
    # Tant que les RT des pics suivants ont moins de 0.04 min en plus (colonne 4), on compare la m/z (+/- 3 (colonne 2)) et la valeur CCS (+/- 4 (colonne 5))
        
    
        while (abs(data2[j,4]-RT)<0.04 & j<=n) {                           # j<n est nécessaire pour éviter que la boucle ne s'arrête à la fin de la liste
            
                 if (abs(data2[j,2]-mass)<3 & abs(data2[j,5]-CCS)<10) {    # Si m/z et CCS sont identiques, c'est le même groupe
                        data2[j,column_groupe]<-groupe                
                 }   
            
                else {                                                      # Si m/z et CCS sont différents et que le pic n'a pas déjà un groupe...
                    if (data2[j,column_groupe]==0){
                        data2[j,column_groupe]<-groupecount+1               # c'est un autre groupe groupe
                        groupecount<-groupecount+1                          # On ajout 1 au total des groupes
                    } else {
                         }                                                  # Si non (pics différents et avec un no de groupe) rien ne se passe, 
                     }                                                   
                     
                                                              
            j<-j+1                                                         # On passe au pics j suivants (pour autant que le RT n'est pas de plus de 0.04 min)
        }
    
      if(data2[j,column_groupe]==0 & j<=n){        # Lorsque la différence de RT devient trop grande (et si on est pas à l'avant dernière ligne)... 
           data2[j,column_groupe]<-groupecount+1   # Si le pic j n'a pas de groupe, on lui en donne un nouveau...
           groupecount<-groupecount+1      
       }   else {}  
                                                    # On fait cela pour tout les pics i...
    }


# Fichier .csv avec l'indication des groupes
write.csv(data2, file = "data2.csv", row.names = FALSE)  # On enregiste un fichier appelé data2

#Par groupe on ne garder que le peak le plus intense + création d'un nouveau fichier avec une colonne pour faire des groupe
s<-split(data2,data2$Groupe)                                            # On crée une liste avec les pics classés par groupe 
data3 <- as.data.frame(matrix(0, ncol = ncol(data2), nrow = length(s))) # On crée un data.frame vide, avec une ligne (pour stocker les pics les plus intenses par groupe)
colnames(data3) <- names(data2)                                         # On renomme les colonnes
groupelist<-unique(data2$Groupe)                                        # On recherche la liste des groupes

for (i in 1: length(groupelist)) {

tempdata<-data2[which(data2$Groupe == groupelist[i]), ]         # On crée un data.frame temporaire qui extrait les pics du même groupe
tempdata<-tempdata[order(-tempdata$Maximum.Abundance),]         # On classe du plus intense au moins intense
data3[i,]<-tempdata[1,]                                         # On stock le pics le plus intense dans le data.frame data3
data3[i,1]<-as.character(tempdata[1,1])                         # Si non le nom change en chiffre
}

# Fichier .csv final avec un seul peak par groupe (le plus intense)
write.csv(data3, file = "data3.csv", row.names = FALSE)

# Recherche des m/z dans la base de données "20180803_Compounds_IJChem"

setwd("C:/Users/nkummer1/switchdrive/MA/Vion/Data Treatment/R/Identification")
database <- data.frame(read.csv("20180816_Compounds_IJChem.csv",sep=";"), headings=TRUE)
data4 <- as.data.frame(data3)
data4$Identifications<- "-"                       # On va utiliser la colonne "IIdentifications" (qui est vide) pour y mettre les id possible


for(i in 1:nrow(data4)){
    accuratemass<-data4[i,2]                   # On fixe la m/z à chaque pic (i)
    id<-database[which(database$Min.m.z...5.ppm. <= accuratemass & database$Max.m.z....5.ppm. >= accuratemass), ] # On cherche dans la base de donnée les composés qui correspondent à la m/z fixé
    if (nrow(id)>1){                               # Si il y a plus de 2 composés qui correspondent...
        allnames<-as.character(id$Description)     # alors on extrait les noms (c'est une liste) 
        x<-allnames[[1]]                           # On écrit le premier nom...
        for (j in 2:nrow(id)) {                    # puis on ajoute les suivants... 
            x<-paste(x,allnames[[j]], sep="; ")
            }
        data4$Identifications[i]<- x
        }
     else if (nrow(id)==1) {                       # Si il y a plus de 1 composé qui correspond...
         allnames<-as.character(id$Description)
         x<-allnames[[1]]
         data4$Identifications[i]<- x
     }
    else {
        
    }
    }

wd<-paste("C:/Users/nkummer1/switchdrive/MA/Vion/Data Treatment/R/",samplename, sep = "")
setwd(wd)
write.csv(data4, file = "data4.csv", row.names = FALSE)

