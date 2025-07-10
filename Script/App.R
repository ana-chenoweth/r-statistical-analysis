# R version: 4.3.3
library(shinydashboard)
library(shiny)
library(deSolve)
library(plotly)
library(shinythemes)
library(shinyWidgets)
library(readr)
library(tidyr)
library(dplyr)
library(leaflet)

Data2020 <- read_csv("Data/DataCov_OAX2020.csv")
Data2021 <- read_csv("Data/DataCov_OAX2021.csv")
Data2022 <- read_csv("Data/DataCov_OAX2022.csv")

source("AuxMap.R")


# ui #
ui <- dashboardPage(skin = "purple",
    dashboardHeader(title = "DASHBOARD"),
    # BARRA LATERAL 
    dashboardSidebar(
      sidebarMenu(
        menuItem("DATOS", tabName = "data", 
                 icon = icon("chart-simple")),
        menuItem("MAPA", tabName = "map", 
                 icon = icon("location-dot")),
        menuItem("CRÉDITOS", tabName = "credits", 
                 icon = icon("users")
        )
      )
    ),
    # DASHBOARD
    dashboardBody(
      tabItems(
        # CUERPO DATOS
        tabItem(tabName = "data",
          fluidRow(
            box(width=4,
              pickerInput(inputId = "año",
                label = "Año",
                choices = c("Todos", "2022", "2021", "2020")
              )
            ),
            valueBoxOutput("TotalBox"),
            valueBoxOutput("TotalDefBox"),
            valueBoxOutput("TotalMujeres"),
            valueBoxOutput("TotalHombres")
          ),
          fluidRow(
            box(width = 12, title = "Cantidad de casos por día de síntomas", 
                plotlyOutput("EvolCasos"))
          ),
          fluidRow(
            box(width = 12, title = "Tabla de resumen de datos por sexo y edad", 
                tableOutput("Resumen"))
          ),
          fluidRow(
            box(width = 12, title = "Cantidad hombres y mujeres contagiados con alguna condición", 
                plotlyOutput("CasosApilados")),
            box(width = 12, title = "Tipo de paciente por Sexo", 
                plotlyOutput("CasosApilados2"))
            #box(width = 12, title = "Tipos de paciente", 
            #    plotlyOutput("TiposPacientes"))
          ),
          fluidRow(
            box(width = 12, title = "Pacientes con alguna comorbilidad",
              box(width = 6, plotlyOutput("Obesidad")),
              box(width = 6, plotlyOutput("Diabetes")),
              box(width = 6, plotlyOutput("Hipertension")),
              box(width = 6, plotlyOutput("Tabaquismo"))
            )
          ),
          fluidRow(
            box(width = 12, plotlyOutput("EdadBoxplot")),
            box(width = 12, plotlyOutput("EdadHistograma"))
          )
        ),
        # CUERPO MAPA
        tabItem(tabName = "map",
          fluidRow(
            box(width=4,
                pickerInput(inputId = "año",
                            label = "Año",
                            choices = c("Todos", "2022", "2021", "2020")
                )
            ),
            box(width=12, title="Mapa municipal con la cantidad de casos",background = "purple",
                leafletOutput("map", width="100%"))
          )
        ),
        # CUERPO CREDITOS
        tabItem(tabName = "credits",
          fluidRow(
            box(width = 10, title="Integrantes",background = "teal",
                style = "height: 140px; overflow-y: auto;",
                p("Denisse Antunez Lopez"),
                p("Ana Laura Chenoweth Galaz"),
                p("Georgina Salcido Valenzuela"),
                p("Omar Pacheco Velasquez")
            ),
            box(width = 10, title="Asignación",background = "green",
                style = "height: 150px; overflow-y: auto;",
                p("Estadística 2024-2"),
                p("Mtra. Mayra Rosalía Tocto Erazo"),
                p("Proyecto final"),
                p("Lic. Ciencias de la Computación")
            )
          )
        )
      )
    )
)


# server #
server <- function(input, output) { 
  
  selected_data <- reactive({
    switch(input$año,
           "2022" = Data2022,
           "2021" = Data2021,
           "2020" = Data2020,
           "Todos" = rbind(Data2022, Data2021, Data2020))
  })
  
  output$TotalBox <- renderValueBox({
    total_casos <- nrow(selected_data())
    valueBox(
      paste0(total_casos), 
      "Total de casos",
      icon = icon("hashtag"),
      color = "green"
    )
  })
  
  output$TotalDefBox <- renderValueBox({
    total_def <- selected_data() %>%
      filter(!is.na(FECHA_DEF)) %>%
      nrow()
    valueBox(
      paste0(total_def), 
      "Total de fallecimientos",
      icon = icon("hashtag"),
      color = "black"
    )
  })
  
  output$TotalMujeres <- renderValueBox({
    total_mujeres <- selected_data() %>%
      filter(SEXO == 1) %>%
      nrow()
    valueBox(
      paste0(total_mujeres), 
      "Total de mujeres contagiadas",
      icon = icon("hashtag"),
      color = "red"
    )
  })
  
  output$TotalHombres <- renderValueBox({
    total_hombres <- selected_data() %>%
      filter(SEXO == 2) %>%
      nrow()
    valueBox(
      paste0(total_hombres), 
      "Total de hombres contagiadas",
      icon = icon("hashtag"),
      color = "blue"
    )
  })
  
  output$EvolCasos <- renderPlotly({
    casos_por_dia <- selected_data() %>%
      filter(!is.na(FECHA_SINTOMAS)) %>%
      group_by(FECHA_SINTOMAS) %>%
      summarise(casos = n()) %>%
      arrange(FECHA_SINTOMAS)
    plot_ly(data = casos_por_dia, 
            x = ~FECHA_SINTOMAS, 
            y = ~casos, 
            type = 'bar',
            marker = list(color = c('#C88BE2'))) %>%
      layout(title = "Cantidad de casos por día",
             xaxis = list(title = "Fecha de Síntomas"),
             yaxis = list(title = "Cantidad de Casos"))
  })
  
  output$Resumen <- renderTable({
    selected_data() %>%
      filter(!is.na(EDAD)) %>%
      group_by(SEXO) %>%
      summarise(
        Media = mean(EDAD, na.rm = TRUE),
        Mediana = median(EDAD, na.rm = TRUE),
        Q1 = quantile(EDAD, 0.25, na.rm = TRUE),
        Q3 = quantile(EDAD, 0.75, na.rm = TRUE),
        Minimo = min(EDAD, na.rm = TRUE),
        Maximo = max(EDAD, na.rm = TRUE),
        `Desviación Estándar` = sd(EDAD, na.rm = TRUE)
      ) %>%
      mutate(SEXO = ifelse(SEXO == 1, "Mujer", 
                           ifelse(SEXO == 2, "Hombre", 
                                  "No especificado")))
  })
  
  output$CasosApilados <- renderPlotly({
    casos_condicion <- selected_data() %>%
      filter(SEXO == 1 | SEXO == 2) %>%
      pivot_longer(cols = c(OBESIDAD, DIABETES, HIPERTENSION),
                   names_to = "Condicion",
                   values_to = "Aplica") %>%
      filter(Aplica == 1) %>%
      group_by(Condicion, SEXO) %>%
      summarise(casos = n(), .groups = "drop") %>%
      mutate(SEXO = ifelse(SEXO == 1, "Mujer", "Hombre"))
    plot_ly(data = casos_condicion,
            x = ~Condicion,
            y = ~casos,
            color = ~SEXO,
            type = 'bar') %>%
      layout(
           # title = "Cantidad de hombres y mujeres contagiados con alguna condición",
             xaxis = list(title = "Condición"),
             yaxis = list(title = "Cantidad de Casos"),
             barmode = 'stack')
  })

 output$CasosApilados2 <- renderPlotly({
    casos_tipo <- selected_data() %>%
      filter(SEXO == 1 | SEXO == 2) %>%
      filter(TIPO_PACIENTE == 1 | TIPO_PACIENTE == 2) %>%
     # pivot_longer(cols = c(TIPO_PACIENTE),
     #             names_to = "Tipo de paciente",
     #             values_to = "Tipo") %>%
      group_by(TIPO_PACIENTE, SEXO) %>%
      summarise(casos = n(), .groups = "drop") %>%
      mutate(SEXO = ifelse(SEXO == 1, "Mujer", "Hombre"),
             TIPO_PACIENTE = ifelse(TIPO_PACIENTE == 1, "Ambulatorio", "Hospitalizado"))
    plot_ly(data = casos_tipo,
            x = ~TIPO_PACIENTE,
            y = ~casos,
            color = ~SEXO,
            type = 'bar') %>%
      layout(
        xaxis = list(title = "Tipo de paciente"),
        yaxis = list(title = "Cantidad de Casos"),
        barmode = 'stack')
  })
  
  # output$TiposPacientes <- renderPlotly({
  #   tipo_paciente <- selected_data() %>%
  #     filter(!is.na(TIPO_PACIENTE)) %>%
  #     group_by(TIPO_PACIENTE) %>%
  #     summarize(casos = n(), .groups = "drop") %>%
  #     mutate(TIPO_PACIENTE = ifelse(TIPO_PACIENTE == 1, "Ambulatorio",
  #                                   ifelse(TIPO_PACIENTE == 2, "Hospitalizado",
  #                                          "No especificado")))%>%
  #     arrange(TIPO_PACIENTE)
  #   plot_ly(data = tipo_paciente,
  #           labels = ~TIPO_PACIENTE,
  #           values = ~casos,
  #           type = 'pie') %>%
  #     layout(title = "Tipo de paciente contagiado")
  # })
  
  output$Obesidad <- renderPlotly({
    padece_obesidad <- selected_data() %>%
      filter(OBESIDAD == 1 | OBESIDAD == 2) %>%
      group_by(OBESIDAD) %>%
      summarize(casos  = n(), .groups = "drop") %>%
      mutate(OBESIDAD = ifelse(OBESIDAD == 1, "Padece",
                               ifelse(OBESIDAD == 2, "No padece",
                                      "No especificado"))) %>%
      arrange(OBESIDAD)
    plot_ly(data = padece_obesidad,
            labels = ~OBESIDAD,
            values = ~casos,
            type = 'pie',
            marker = list(colors = c('#A2BBF1', '#91E28B', 'gray'))) %>%
      layout(title = "Pacientes con obesidad")
  })
  
  output$Diabetes <- renderPlotly({
    padece_diabetes <- selected_data() %>%
      filter(DIABETES == 1 | DIABETES == 2) %>%
      group_by(DIABETES) %>%
      summarize(casos  = n(), .groups = "drop") %>%
      mutate(DIABETES = ifelse(DIABETES == 1, "Padece",
                               ifelse(DIABETES == 2, "No padece",
                                      "No especificado"))) %>%
      arrange(DIABETES)
    plot_ly(data = padece_diabetes,
            labels = ~DIABETES,
            values = ~casos,
            type = 'pie',
            marker = list(colors = c('#A2BBF1', '#91E28B', 'gray'))) %>%
      layout(title = "Pacientes con diabetes")
  })
  
  output$Hipertension <- renderPlotly({
    padece_hipertension <- selected_data() %>%
      filter(HIPERTENSION == 1 | HIPERTENSION == 2) %>%
      group_by(HIPERTENSION) %>%
      summarize(casos  = n(), .groups = "drop") %>%
      mutate(HIPERTENSION = ifelse(HIPERTENSION == 1, "Padece",
                               ifelse(HIPERTENSION == 2, "No padece",
                                      "No especificado"))) %>%
      arrange(HIPERTENSION)
    plot_ly(data = padece_hipertension,
            labels = ~HIPERTENSION,
            values = ~casos,
            type = 'pie',
            marker = list(colors = c('#A2BBF1', '#91E28B', 'gray'))) %>%
      layout(title = "Pacientes con hipertensión")
  })
  
  output$Tabaquismo <- renderPlotly({
    padece_tabaquismo <- selected_data() %>%
      filter(TABAQUISMO == 1 | TABAQUISMO == 2) %>%
      group_by(TABAQUISMO) %>%
      summarize(casos  = n(), .groups = "drop") %>%
      mutate(TABAQUISMO = ifelse(TABAQUISMO == 1, "Padece",
                                   ifelse(TABAQUISMO == 2, "No padece",
                                          "No especificado"))) %>%
      arrange(TABAQUISMO)
    plot_ly(data = padece_tabaquismo,
            labels = ~TABAQUISMO,
            values = ~casos,
            type = 'pie',
            marker = list(colors = c('#A2BBF1', '#91E28B', 'gray'))) %>%
      layout(title = "Pacientes con tabaquismo")
  })
  
  output$EdadHistograma <- renderPlotly({
    sexo_tipopaciente <- selected_data() %>%
      mutate(
        SEXO = ifelse(SEXO == 1, "Mujer", 
                      ifelse(SEXO == 2, "Hombre", "No especificado")),
        TIPO_PACIENTE = ifelse(TIPO_PACIENTE == 1, "Ambulatorio", 
                               ifelse(TIPO_PACIENTE == 2, "Hospitalizado", "No especificado"))
      )
    plot_ly(data = sexo_tipopaciente, 
            x = ~EDAD, 
            color = ~interaction(SEXO, TIPO_PACIENTE, sep = " - "),  
            type = 'histogram',
            histnorm = 'count') %>% 
      layout(title = "Distribución de Edad por Sexo y Tipo de Paciente",
             xaxis = list(title = "Edad"),
             yaxis = list(title = "Frecuencia"))
  })
  
  output$EdadBoxplot <- renderPlotly({
    sexo_tipopaciente <- selected_data() %>%
      mutate(
        SEXO = ifelse(SEXO == 1, "Mujer", 
                      ifelse(SEXO == 2, "Hombre", "No especificado")),
        TIPO_PACIENTE = ifelse(TIPO_PACIENTE == 1, "Ambulatorio", 
                               ifelse(TIPO_PACIENTE == 2, "Hospitalizado", "No especificado"))
      )
    
    plot_ly(data = sexo_tipopaciente,
            y = ~EDAD,
            x = ~interaction(SEXO, TIPO_PACIENTE, sep = " - "), 
            color = ~interaction(SEXO, TIPO_PACIENTE, sep = " - "),
            type = 'box') %>%
      layout(title = "Boxplot de Edad por Sexo y Tipo de Paciente",
             xaxis = list(title = "Sexo - Tipo de Paciente"),
             yaxis = list(title = "Edad"))
  })
  
  output$map <- renderLeaflet({
    casos_municipios <- selected_data() %>% 
      mutate(MUNICIPIO_RES = sprintf("%03d", as.numeric(MUNICIPIO_RES))) %>% 
      group_by(MUNICIPIO_RES) %>%
      summarise(casos = n()) %>%
      left_join(municipios %>% mutate(MUNICIPIO_RES = sprintf("%03d", as.numeric(MUNICIPIO_RES))), 
                by = "MUNICIPIO_RES") %>%
      mutate(info = paste0(nombre_municipio, ": ", casos, " casos")) %>%
      filter(!is.na(lat) & !is.na(long))
    
    leaflet(casos_municipios) %>%
      addTiles() %>%
      setView(lng = -96.5773, lat = 17.1026, zoom = 7) %>%
      addMarkers(lng = ~long, lat = ~lat, label = ~info)
  })
    
  
}

shinyApp(ui, server)
