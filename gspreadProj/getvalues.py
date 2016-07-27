#!/usr/bin/env python

## Author : Krishna Muriki
## Date : June 3rd 2016
##
## This Python script needs oauth2client and gspread libraries
####################################################################

import logging
logging.captureWarnings(True)
import shlex, subprocess

import gspread
from oauth2client.service_account import ServiceAccountCredentials
    
### GLOBAL VARIABLES
#################################

GACCESS_KEYFILE = "BRCNuclearAppAccess-6bde038bfef4.json"
SPREADSHEET_KEY = "1KfDhi61aTQNbnL0kBwYc103dfxKMMbUzQAShbZ_0X28"
SPREADSHEET_TABNAME = "App list"

DATAROW = 42
DATACOL_START = 4

def main():
    scope = ['https://spreadsheets.google.com/feeds']
    credentials = ServiceAccountCredentials.from_json_keyfile_name(GACCESS_KEYFILE, scope)
    gc = gspread.authorize(credentials)

    sheet = gc.open_by_key(SPREADSHEET_KEY)
    worksheet = sheet.worksheet(SPREADSHEET_TABNAME)

    i = 0
    newline = worksheet.cell(DATAROW,DATACOL_START+i).value
   
    while ( newline != "" ):
	#print newline
        print newline
	#Execute the command
	returnvalue = subprocess.call(["/usr/bin/perl","./updateBRCNuclearGroups.pl","-g",newline,"-c"])

        i = i+1
	newline = worksheet.cell(DATAROW,DATACOL_START+i).value
    
#main
main()

