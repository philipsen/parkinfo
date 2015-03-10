
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
d$duration <- as.numeric(d$endD - d$startD) / 60
d <- d[order(d$startD, decreasing = T), ]
total_minutes <- sum(d$duration)
pm = round(total_minutes / ((408 + 360) * 60) * 100, 1)
py <- round((yday(Sys.time()) - 31 - 28) / 365 * 100, 1)


kentekens <- mongo.find.all(mongo, k, data.frame = TRUE)
m <- match(d$kenteken, kentekens$kenteken)
d <- cbind(d, 'kleur' = kentekens[m, 'kleur'], 'type' = str_c(kentekens$merk, kentekens$naam, sep=' ')[m])
#names(d)[8] <- 'kleur'
#names(d)[9] <- 'type'


shinyServer(function(input, output) {

  print("here 2")
  
  output$distPlot <- renderPlot({
    ggplot(d, aes(x = (as.Date(startD, 'day')), 
                  y = duration, fill = kenteken)) +
      geom_bar(stat = "identity") + 
      labs(x = "datum", y = "aantal minuten",
           title = 'Aantal minuten per dag, gesplitst per auto') +
      scale_x_date(limits = c(as.Date("2015-3-1"), 1 + as.Date(Sys.time())))
    
  })
 
  tab <- subset(d, select=c(start, end, duration, kenteken, kleur, type))
  ds <- str_c(d$duration %% 60, " minuten")
  ds[d$duration %% 60 == 0] <- ''
  ds[d$duration > 59] <- str_c(floor(d$duration[d$duration > 59] / 60), " uur en ", ds[d$duration > 59])
  tab$duration <- ds
  output$view <- renderTable({
    tab
    
  }, include.rownames = FALSE, digits = 0)

  
  output$tot_time <- renderText(paste("Totaal gebruikt:", floor(total_minutes / 60),
                                      "uur en", (total_minutes %% 60), "minuten"))
  output$tot_per <- renderText(paste(pm, "% van de uren gebruikt in", 
                                     py,
                                     "% van de dagen"))
})

