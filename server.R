
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)

library(rmongodb)
library(ggplot2)
library(lubridate)
library(xtable)
library(stringr)

mongo <- mongo.create()
dbs <- mongo.get.databases(mongo)
db <- "parkingDb"
#collections <- mongo.get.database.collections(mongo, db)
c <- 'parkingDb.reservations'
k <- 'parkingDb.kentekens'
print(mongo.count(mongo, c))
#mongo.find.one(mongo, c)
d <- mongo.find.all(mongo, c, data.frame = TRUE)
d$startD <- strptime(d$start, "%d-%m-%Y %H:%M")
d$endD <- strptime(d$end, "%d-%m-%Y %H:%M")
d$duration <- as.numeric(d$endD - d$startD)
d <- d[order(d$startD, decreasing = T), ]

kentekens <- mongo.find.all(mongo, k, data.frame = TRUE)
m <- match(d$kenteken, kentekens$kenteken)
d <- cbind(d, 'kleur' = kentekens[m, 'kleur'], 'type' = str_c(kentekens$merk, kentekens$naam, sep=' ')[m])
#names(d)[8] <- 'kleur'
#names(d)[9] <- 'type'


shinyServer(function(input, output) {

  print("here 2")
  
  output$distPlot <- renderPlot({

    # generate bins based on input$bins from ui.R
    #x    <- faithful[, 2]
    #bins <- seq(min(x), max(x), length.out = input$bins + 1)

    # draw the histogram with the specified number of bins
    #hist(x, breaks = bins, col = 'skyblue', border = 'black', main = "aap")
    ggplot(d, aes(x = as.character(floor_date(startD, 'day')), 
                  y = round(duration / 60, 0), fill = kenteken)) +
      geom_bar(stat = "identity") + 
      labs(x = "datum", y = "aantal minuten",
           title = 'Aantal minuten per dag, gesplitst per auto')
    
  })
  
  
  output$view <- renderTable({
    tab <- subset(d, select=c(start, end, duration , kenteken, kleur, type))
  }, include.rownames = FALSE)

})
