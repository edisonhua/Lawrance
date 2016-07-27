import gspread 
import time
from oauth2client.service_account import ServiceAccountCredentials

Key_File = "MyProject-55b9a55365f2.json"
def main():
	scope = ['https://spreadsheets.google.com/feeds']

	credentials = ServiceAccountCredentials.from_json_keyfile_name(Key_File, scope)
	gc = gspread.authorize(credentials)
	print 'getting values', gc

	print 'running the open_by_key'
	sh = gc.open_by_key('1dzeUJHLZIcIKl3mlMfY5-uFluTwPcVGNHW3OqcSViOY')
	print 'shit went through'
	worksheet = sh.get_worksheet(0)
	
	val = worksheet.acell('B1').value #show value in B1
	print "value before change when there's single worksheet was :", val

	worksheet.update_acell('B1', '42') #change value in B1 to 42 from asdasd
	val2 = worksheet.acell('B1').value
	t1 = (time.strftime("%m-%d-%Y %H:%M:%S"))
	worksheet.update_acell('G1', str(t1))
	print 'value changing right now, and it is changing in B1 from ', val, 'to', val2
	print 'current time is :', t1


#	newwks = sh.add_worksheet(title="new added for testing", rows="20", cols="20") #add a new worksheet
#	print 'new worksheet added as title', newwks
	newwks = sh.get_worksheet(2)
	newwks.update_acell('A1', '33') #update cell A1 to 33 from empty
	val3 = newwks.acell('A1').value
	print 'cell A1 is updated to :', val3

	cell_list = worksheet.range('A1:B2')
	for cell in cell_list:
		cell.value = str(t1)
	worksheet.update_cells(cell_list)
	print 'worksheet, Sheet1, was changed on A1:B2 from original values to 123'

#generate the date of the worksheet is running
main()