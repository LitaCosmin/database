install.packages('tidyverse')
library(tidyverse)
## curatare sesiune curenta
rm(list = ls())
 install.packages('RPostgreSQL')
library(RPostgreSQL)
## incarcare driver PostgreSQL
drv <- dbDriver("PostgreSQL")
###  A. Stabilirea conexiunii cu BD PostgreSQL
## Windows
con <- dbConnect(drv, dbname="proiectfinal", user="postgres",
                 host = 'localhost', password="postgres",port='5432')
###  B. Extragerea numelui fiecarei tabele
tables <- dbGetQuery(con,
                     "select table_name from information_schema.tables where table_schema = 'public'")
tables
###  C. Importul tuturor tabelelor
for (i in 1:nrow(tables)) {
  # extragrea tabelei din BD PostgreSQL
  temp <- dbGetQuery(con, paste("select * from ", tables[i,1], sep=""))
  # crearea dataframe-ului
  assign(tables[i,1], temp)
}
###  D. inchidere conexiuni PostgreSQL
for (connection in dbListConnections(drv) ) {
  dbDisconnect(connection)
}
###  E. Descarcare (din memorie) a driverului
dbUnloadDriver(drv)
###  F. Salvarea tuturor dataframe-urilor din
###  sesiunea curenta ca fisier .writeData
# # stergere obiecte inutile
rm(con, drv, temp, i, tables, connection)
#setwd()
setwd('E:/Facultate FEAA/FACULTATE anul 2/SEM 2/Baze de date 1/seminar/PROIECT/PROIECT')
getwd()
# salvare
save.image(file = 'proiect.RData')
# stergerea tuturor obiectelor din sesiunea curenta R
rm(list = ls())
load(file = 'proiect.RData')
install.packages('magrittr')
library(magrittr)
install.packages("dplyr")
library(dplyr)
install.packages('tidyr')
library(tidyr)
install.packages('rlang')
library(rlang)

##Liță Cosmin-Constantin
##1)grupare si filtrare
## Care sunt clientii care au cumparat fuste si cate bucati au cumparat efectiv(doar comenzile EFECTUATE)?
temp<-clienti%>%
  inner_join(comenzi_preluate,by=c('id_client'='id_client'))%>%
  inner_join(detalii_comenzi,by=c('id_comanda'='id_comanda'))%>%
  inner_join(produse,by=c('id_produs'='id_produs'))%>%
  inner_join(tip_produs,by=c('cod_tip_produs'='cod_tip_produs'))%>%
  filter(descriere_produs=='fusta'& status_comanda=='efectuata' & status_produs=='in stoc')%>%
  group_by(id_client)%>%
  summarise (numar_prod=n())
print(temp)

##2)subconsultari
##Care este tipul produselor vandute intr-un numar mai mare decat blugii?
temp<-tip_produs%>%
  inner_join(produse,by=c('cod_tip_produs'='cod_tip_produs'))%>%
  inner_join(detalii_comenzi,by=c('id_produs'='id_produs'))%>%
  inner_join(comenzi_preluate,by=c('id_comanda'='id_comanda'))%>%
  filter(status_comanda=='efectuata')%>%
  group_by(descriere_produs)%>%
  summarise (numar_prod=n())%>%
  filter(numar_prod>
           (tip_produs%>%
              inner_join(produse,by=c('cod_tip_produs'='cod_tip_produs'))%>%
              inner_join(detalii_comenzi,by=c('id_produs'='id_produs'))%>%
              inner_join(comenzi_preluate,by=c('id_comanda'='id_comanda'))%>%
              filter(status_comanda=='efectuata'& descriere_produs=='blugi')%>%
              tally() %>%
              pull()
           )
     
  )
print(temp)
##3) tabele pivot
## Primele 3 tipuri de produse livrate catre fiecare client(indiferent daca este persoana fizica sau juridica) 
##         si numarul total de produse comandate pana atunci

temp<-separate((distinct(tip_produs%>%
                           inner_join(produse,by=c('cod_tip_produs'='cod_tip_produs'))%>%
                           inner_join(detalii_comenzi,by=c('id_produs'='id_produs'))%>%
                           inner_join(comenzi_preluate,by=c('id_comanda'='id_comanda'))%>%
                           group_by(id_client)%>%
                           select(descriere_produs,id_client))%>%
                  summarise(prod1_prod2_prod3=paste(descriere_produs,collapse = '- '))),col=prod1_prod2_prod3,into=c("Prod1","Prod2","Prod3"),sep="-",fill='right')%>%
  mutate(Prod2=if_else(is.na(Prod2),'-',Prod2))%>%
  mutate(Prod3=if_else(is.na(Prod3),'-',Prod3))%>%
  inner_join(tip_produs%>%
               left_join(produse,by=c('cod_tip_produs'='cod_tip_produs'))%>%
               left_join(detalii_comenzi,by=c('id_produs'='id_produs'))%>%
               left_join(comenzi_preluate,by=c('id_comanda'='id_comanda'))%>%
               group_by(id_client)%>%
               select(id_client)%>%
               summarise(id_produs=n()),by=c('id_client'='id_client'))%>%
  transmute('id_client'=id_client,'Produs1'=Prod1,'Produs2'=Prod2,'Produs3'=Prod3,'Total_numar_produse'=id_produs)
new_row<-data.frame('Total','-','-','-',(detalii_comenzi%>%
                                           count()))
names(new_row)<-names(temp)
temp<-rbind(temp,new_row)
print(temp)
##---Sa se afle produsele si marimile de pe fiecare comanda a clientilor
temp<-comenzi_preluate%>%
  inner_join(detalii_comenzi,by=c('id_comanda'="id_comanda"))%>%
  inner_join(produse,by=c('id_produs'='id_produs'))%>%
  group_by(id_client,id_comanda)%>%
  summarise(lista_produse=paste(nume_prod,'(',marime_prod,')', collapse=';'))
  print(temp)

## 4) interogare pseudo-recursiva
##CERINTA:Sa se numeroteze toate produsele de pe fiecare comanda a clientilor
temp <- comenzi_preluate %>%
  inner_join(detalii_comenzi,by=c('id_comanda'='id_comanda')) %>%
  inner_join(produse,by=c('id_produs'='id_produs')) %>%
  arrange(id_comanda) %>%                   
  group_by(id_comanda,id_client) %>%
  mutate (numar_prod = row_number()) %>%
  summarise(produse_comanda = paste(paste0(numar_prod, ':', nume_prod), collapse = '; ')) %>%
  ungroup()
print(temp)


#1.Cate metode de plata au ales clientii din judetul Galati?
temp<-clienti %>%
  inner_join(clienti_metoda_de_plata, by=c('id_client'='id_client'))%>%
  inner_join(metode_de_plata,by=c('cod_met_plata'='cod_met_plata'))%>%
  filter(jud =='Galati')%>%
  group_by(id_client)%>%
  summarise(numar_met_plata=n())
print(temp)
##2. Care sunt angajatii care au preluat mai multe comenzi decat Toader Andreea?
temp<- angajati%>%
  inner_join(comenzi_preluate, by=c('id_angajat'='id_angajat'))%>%
  select(nume_angajat)%>%
  group_by(nume_angajat)%>%
  summarise(numar_de_comenzi=n())%>%
  filter(numar_de_comenzi >
           (angajati%>%
              inner_join(comenzi_preluate, by=c('id_angajat'='id_angajat'))%>%
              filter(nume_angajat=='Toader Andreea')%>%
              tally()%>%
              pull()
            
           ))
  print(temp)
##3. -aflati numarul platii si sumele pentru anii 2018,2019,2020 si totalul general pe ani.
temp<- plati%>%
  inner_join(clienti_metoda_de_plata, by=c('id_client_plata'='id_client_plata'))%>%
  inner_join(clienti,by=c('id_client'='id_client'))%>%
  transmute(id_client, suma_plata, year = lubridate::year(data_plata))%>%
  filter(year %in% c(2018,2019,2020))%>%
  group_by(id_client, year)%>%
  summarise(vanzari=sum(suma_plata))%>%
  ungroup()%>%
  spread(year, vanzari, fill=0)%>%
  spread(year, vanzari, fill=0)%>%
  arrange(id_client)
print(temp)
##4. sa se afle sumele de plata pt fiecare client
temp<-comenzi_preluate%>%
  inner_join(facturi,by=c('id_comanda'="id_comanda"))%>%
  inner_join(plati,by=c('numar_fact'='numar_fact'))%>%
  group_by(id_client)%>%
  summarise(lista_produse=paste(numar_fact,'(',suma_plata,')', collapse=';'))
print(temp)


##1) Afisati numarul clientilor de gen feminin din Romania grupati pe orase.
temp<-clienti %>%
  inner_join(clienti_pf,by=c('id_client'='id_client_pf'))%>%
  filter(tara=='Romania' & gen=='F')%>%
  group_by(oras)%>%
  summarise(numar_clienti=n())
print(temp)

##2)Ce facturi s-au emis in prima luna calendaristica a vanzarilor ?
temp <- facturi %>%
  inner_join(
    facturi %>%
      top_n(-1, data_fact) %>%
      select (data_fact)
    print(temp)
  )
##3)Care sunt clientii care au mai putine comenzi date decat clientul 1230?
temp <- comenzi_preluate %>%
  group_by(id_comanda) %>%
  summarise (nr_de_comenzi= n()) %>%
  ungroup() %>%
  mutate (numar_comenzi = if_else(id_client == '1230', nr_de_comenzi, 0L)) %>%  
  mutate (numar_comenzi = max(numar_comenzi)) %>%
  filter (nr_de_comenzi < numar_comenzi)
print(temp)

##4)Sa se afle produsele cu discount din fiecare comanda
temp<-comenzi_preluate%>%
  inner_join(detalii_comenzi,by=c('id_comanda'="id_comanda"))%>%
  inner_join(produse,by=c('id_produs'='id_produs'))%>%
  inner_join(discount,by=c('id_produs'='id_produs_disc'))%>%
  group_by(id_comanda)%>%
  summarise(lista_produse=paste(nume_prod,'(',discount,')', collapse=';'))
 print(temp)


