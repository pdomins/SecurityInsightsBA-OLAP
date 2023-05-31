# SecurityInsightsBA-OLAP

## Data Source
The data used in this project is sourced from the Buenos Aires Open Data portal (https://data.buenosaires.gob.ar/dataset/), which provides publicly available datasets related to various aspects of the city.

## Scripts
### ba_geom.sql
The `ba_geom.sql` script generates tables that contain geographical information about Buenos Aires. These tables include data on subway stations, police stations, communes, and neighborhoods within the Ciudad Autónoma de Buenos Aires. This geographical information enhances the analysis and provides context for understanding the spatial aspects of criminality data.

### date.sql
The `date.sql` script generates a table that encompasses all dates from January 1, 2016, to December 31, 2021. This date range corresponds to the available criminality data we have. The table serves as a reference for performing temporal analysis and enables querying the data based on specific dates, months, or years.

### ba_crimes.sql
The `ba_crimes.sql` script generates a table that includes detailed information about crimes committed in the Ciudad Autónoma de Buenos Aires (CABA) from 2016 to 2021. The table includes fields such as crime type, sub-type, date, approximate time slot, coordinates, and other relevant information. This data provides the foundation for performing analysis on crime patterns, trends, and correlations with other factors.

## Note
Please note that if you intend to use the scripts, you should change the `set path` statement within the scripts to your own local absolute path where the CSV files are located. The `COPY` function in SQL only works with absolute paths. Make sure to update the path accordingly to ensure the scripts can access the CSV files on your system.

## Disclaimer
It is important to note that the usage of the data is strictly for educational purposes. The project respects the terms and conditions set by the Buenos Aires Open Data portal, and the data is used in accordance with the provided guidelines.