# SecurityInsightsBA-OLAP

## Data Source
The data used in this project is sourced from the Buenos Aires Open Data portal (https://data.buenosaires.gob.ar/dataset/), which provides publicly available datasets related to various aspects of the city.

## Scripts
To ensure the proper creation of dependencies and the correct functioning of the data warehouse, it is essential to execute the scripts in the following order:

### ba_geom.sql
The `ba_geom.sql` script generates tables that contain geographical information about Buenos Aires. These tables include data on subway stations, police stations, communes, and neighborhoods within the Ciudad Autónoma de Buenos Aires. This geographical information enhances the analysis and provides context for understanding the spatial aspects of criminality data.

### datetime.sql
The datetime.sql script generates a table that encompasses all dates and time ranges from January 1, 2016, to December 31, 2021, including the 24 hours of each day. This date range corresponds to the available criminality data we have. The table serves as a reference for performing temporal analysis and enables querying the data based on specific dates, months, or years, and their corresponding hours.

### ba_crimes.sql
The `ba_crimes.sql` script generates a table that includes detailed information about crimes committed in the Ciudad Autónoma de Buenos Aires from 2016 to 2021. The table includes fields such as crime type, sub-type, date, approximate time slot, coordinates, and other relevant information. This data provides the foundation for performing analysis on crime patterns, trends, and correlations with other factors.

### ba_paths.sql
The `ba_paths.sql` script generates a table that contains the 'safe paths' from schools to nearby locations with high pedestrian traffic. This information can be utilized to analyze and identify safer routes for students and pedestrians. Additionally, the script creates a table specifically for schools, which includes relevant data such as school names, CUE, and coordinates.

## Note
Please note that if you intend to use the scripts, you should change the `<set_path>` statement within the scripts with your own local absolute path where the CSV files are located. The `COPY` function in SQL only works with absolute paths. Make sure to update the path accordingly to ensure the scripts can access the CSV files on your system.

## Disclaimer
It is important to note that the usage of the data is strictly for educational purposes. The project respects the terms and conditions set by the Buenos Aires Open Data portal, and the data is used in accordance with the provided guidelines.