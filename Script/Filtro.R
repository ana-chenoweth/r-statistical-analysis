library(readr)
library(tidyverse)
library(dplyr)

# leer las bases de datos
DataCovid2020 <- read_csv("Data/COVID19_2020_CONFIRMADOS.csv")
DataCovid2021 <- read_csv("Data/COVID19_2021_CONFIRMADOS.csv")
DataCovid2022 <- read_csv("Data/COVID19_2022_CONFIRMADOS.csv")

# filtrar el estado de oaxaca
DataCov_OAX2020 <- DataCovid2020 %>% filter(ENTIDAD_RES == 20)
write_csv(DataCov_OAX2020, "Data/DataCov_OAX2020.csv")

DataCov_OAX2021 <- DataCovid2021 %>% filter(ENTIDAD_RES == 20)
write_csv(DataCov_OAX2021, "Data/DataCov_OAX2021.csv")

DataCov_OAX2022 <- DataCovid2022 %>% filter(ENTIDAD_RES == 20)
write_csv(DataCov_OAX2022, "Data/DataCov_OAX2022.csv")

# leer la bases de datos filtrada
Data2020 <- read_csv("Data/DataCov_OAX2020.csv")
Data2021 <- read_csv("Data/DataCov_OAX2021.csv")
Data2022 <- read_csv("Data/DataCov_OAX2022.csv")
