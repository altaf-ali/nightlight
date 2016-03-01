# Nighttime Lights Data

Nightlight data used in this project is based on the satellite composites from National Oceanic and Atmospheric Administration (NOAA). We use the cleaned up dataset from NOAA that excludes cloud cover and ephemeral events. Sunlit data, moonlit data, and glare are also excluded.
 
### Data Source
NOAA datasets can be downloaded from this link: https://ngdc.noaa.gov/eog/dmsp/downloadV4composites.html

### Yearly Coverage
  - The dataset covers all years from 1992 to 2013.
  
    The following table from NOAA shows the satellite(s) covering each year.
    
    Year | F10 | F12 | F14 | F15 | F16 | F18 |
    -----|-----|-----|-----|-----|-----|-----|
    1992 | F101992 | - | - | - | - | - |
    1993 | F101993 | - | - | - | - | - |
    1994 | F101994 | F121994 | - | - | - | - |
    1995 | - | F121995 | - | - | - | - |
    1996 | - | F121996 | - | - | - | - |
    1997 | - | F121997 | F141997 | - | - | - |
    1998 | - | F121998 | F141998 | - | - | - |
    1999 | - | F121999 | F141999 | - | - | - |
    2000 | - | - | F142000 | F152000 | - | - |
    2001 | - | - | F142001 | F152001 | - | - |
    2002 | - | - | F142002 | F152002 | - | - |
    2003 | - | - | F142003 | F152003 | - | - |
    2004 | - | - | - | F152004 | F162004 | - |
    2005 | - | - | - | F152005 | F162005 | - |
    2006 | - | - | - | F152006 | F162006 | - |
    2007 | - | - | - | F152007 | F162007 | - |
    2008 | - | - | - |	- | F162008 | - |
    2009 | - | - | - | 	- | F162009 | - |
    2010 | - | - | - | - | - | F182010 |
    2011 | - | - | - | - | - | F182011 |
    2012 | - | - | - | - | - | F182012 |
    2013 | - | - | - | - | - | F182013 |
    
  As we can see, some years have overlapping satellites so we ignore the data from the phased out satellite and keep only the new one.
    
### Spatial Resolution
  - The resolution of nightlight data is 30 arc second grids (with 1 arc second roughly equivalent to 31 meters or 100 feet of ground distance.)
    We resample the nightlight data to match the resolution of population grids from GPW at 2.5 arc second or approximately 5km (at the equator).
    TODO: find out how the resample function does this. Does it just do a mean of all higher resolution grids?

### Coordinate System
  - The nightlight data follows the same coordinate system (WGS84) as GPW so no transformation is necessary to align grid cells.
  
### Range
  - The data values for nightlight data are within the range of 0 to 63.
  - Areas where no cloud-free observations were collected are represented by the value 255.

### Source:
  Image and data processing by NOAA's National Geophysical Data Center.
  DMSP data collected by US Air Force Weather Agency.
  https://ngdc.noaa.gov/eog/dmsp/downloadV4composites.html
  
  
