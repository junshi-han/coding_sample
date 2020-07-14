#-*-coding:utf-8-*-
import requests
import ast
import os
# from selenium import webdriver
# from selenium.webdriver.support.ui import Select
from lxml import etree
import random
import time
import datetime
import webbrowser
import xlwt
import xlrd
import pandas as pd
import numpy as np
import csv
from numba import autojit
import tushare as ts
import subprocess
import math

requests.adapters.DEFAULT_RETRIES = 10
s = requests.session()
s.keep_alive = False

@autojit

def today_inflow_archive():
	# get data of today's inflow of each stock, and write into file "yyyymmdd.xls"
	headers={'User-Agent':'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.61 Safari/537.36'}
	eastmoney_url='http://push2.eastmoney.com/api/qt/clist/get?pn=1&pz=3991&po=1&np=1&ut=b2884a393a59ad64002292a3e90d46a5&fltt=2&invt=2&fid0=f4001&fid=f184&fs=m:0+t:6+f:!2,m:0+t:13+f:!2,m:0+t:80+f:!2,m:1+t:2+f:!2,m:1+t:23+f:!2,m:0+t:7+f:!2,m:1+t:3+f:!2&stat=1&fields=f12,f14,f2,f3,f62,f184,f66,f69,f72,f75,f78,f81,f84,f87&rt=53093393&cb=jQuery183048596949919181065_1592798333337&_=1592801801925'
	pythonlink='https://www.zhihu.com/question/35943142'
	response=requests.get(eastmoney_url,headers=headers)
	start=response.text.find('(')
	end=response.text.find(')')
	print(start,end)
	str_data=response.text[start+1:end]
	dic_data=ast.literal_eval(str_data)
	str_date=str(datetime.datetime.utcnow()+datetime.timedelta(hours=8))[0:10]
	str_date=str_date.replace('-','')
	str_time=str(datetime.datetime.utcnow()+datetime.timedelta(hours=8))[11:16]
	str_time=str_time.replace(':','')
	daily_inflow_archive_folder='C:\\Users\\star\\Desktop\\trade\\inflow_data_archive\\'
	workbook = xlwt.Workbook(encoding = 'utf-8')
	worksheet = workbook.add_sheet('inflow')
	worksheet.write(0,0,'code')
	worksheet.write(0,1,'name')
	worksheet.write(0,2,'price')
	worksheet.write(0,3,'price_change')
	worksheet.write(0,4,'inflow')
	worksheet.write(0,6,'today_inflow_huge')
	worksheet.write(0,8,'today_inflow_big')
	worksheet.write(0,10,'today_inflow_mid')
	worksheet.write(0,12,'today_inflow_small')
	for count in range(0,3991):
		f12 = dic_data['data']['diff'][count]['f12']
		f14 = dic_data['data']['diff'][count]['f14']
		f2 = dic_data['data']['diff'][count]['f2']
		f3 = dic_data['data']['diff'][count]['f3']
		f62 = dic_data['data']['diff'][count]['f62']
		f184 = dic_data['data']['diff'][count]['f184']
		f66 = dic_data['data']['diff'][count]['f66']
		f69 = dic_data['data']['diff'][count]['f69']
		f72 = dic_data['data']['diff'][count]['f72']
		f75 = dic_data['data']['diff'][count]['f75']
		f78 = dic_data['data']['diff'][count]['f78']
		f81 = dic_data['data']['diff'][count]['f81']
		f84 = dic_data['data']['diff'][count]['f84']
		f87 = dic_data['data']['diff'][count]['f87']
		worksheet.write(count+1,0,f12)
		worksheet.write(count+1,1,f14)
		worksheet.write(count+1,2,f2)
		worksheet.write(count+1,3,f3)
		worksheet.write(count+1,4,f62)
		worksheet.write(count+1,5,f184)
		worksheet.write(count+1,6,f66)
		worksheet.write(count+1,7,f69)
		worksheet.write(count+1,8,f72)
		worksheet.write(count+1,9,f75)
		worksheet.write(count+1,10,f78)
		worksheet.write(count+1,11,f81)
		worksheet.write(count+1,12,f84)
		worksheet.write(count+1,13,f87)
	workbook.save(daily_inflow_archive_folder+str_date+'.xls')

# today_inflow_archive()


# 流通市值:value

def today_value_archive():
	str_date=str(datetime.datetime.utcnow()+datetime.timedelta(hours=8))[0:10]
	str_date=str_date.replace('-','')
	value_url='http://xuanguapi.eastmoney.com/Stock/JS.aspx?type=xgq&sty=xgq&token=eastmoney&c=[cz20(4|0w)]&p=1&jn=mWUgSiOB&ps=4000&s=cz20(4|0w)&st=-1&r=1593915802118'
	headers={'User-Agent':'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.61 Safari/537.36'}
	response=requests.get(value_url,headers=headers)
	start=response.text.find('=')
	dic_data=ast.literal_eval(response.text[start+1:])
	list_data=dic_data['Results']
	table_data=np.zeros(shape=(len(list_data),2))
	for i in range(0,len(list_data)):
		temp_list=list_data[i].split(',')
		table_data[i][0]=temp_list[1]
		table_data[i][1]=value=temp_list[3]
	data = pd.DataFrame({'code': table_data[:, 0], 'value': table_data[:, 1]})
	data.to_stata('C:\\Users\\star\\Desktop\\trade\\value_data_archive\\'+str_date+'.dta')
	data.to_excel('C:\\Users\\star\\Desktop\\trade\\value_data_archive\\'+str_date+'.xls')

# today_value_archive()


def today_tr_archive():
	tr_url='http://q.jrjimg.cn/?q=cn|s|sa&c=s,ta,tm,sl,cot,cat,ape&n=hqa&o=tr,d&p=1100&_dc=1593939870295'
	headers={'User-Agent':'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.61 Safari/537.36'}
	response=requests.get(tr_url,headers=headers)
	time.sleep(15)
	start=response.text.find('=')
	oneline_text=response.text.replace('\n','')
	oneline_text=oneline_text.replace('\r','')
	oneline_text=oneline_text.replace(',ta:',',\'ta\':')
	oneline_text=oneline_text.replace('Summary','\'Summary\'')
	oneline_text=oneline_text.replace('Column','\'Column\'')
	oneline_text=oneline_text.replace('HqData','\'HqData\'')
	oneline_text=oneline_text.replace('mstat','\'mstat\'')
	oneline_text=oneline_text.replace('page:','\'page\':')
	oneline_text=oneline_text.replace('pages','\'pages\'')
	oneline_text=oneline_text.replace('totalh','\'totalh\'')
	oneline_text=oneline_text.replace('total:','\'total\':')
	oneline_text=oneline_text.replace('hqtime','\'hqtime\'')
	oneline_text=oneline_text.replace('id','\'id\'')
	oneline_text=oneline_text.replace('code','\'code\'')
	oneline_text=oneline_text.replace('name','\'name\'')
	oneline_text=oneline_text.replace('lcp','\'lcp\'')
	oneline_text=oneline_text.replace('stp','\'stp\'')
	oneline_text=oneline_text.replace('np','\'np\'')
	oneline_text=oneline_text.replace('tm','\'tm\'')
	oneline_text=oneline_text.replace('hlp','\'hlp\'')
	oneline_text=oneline_text.replace('pl','\'pl\'')
	oneline_text=oneline_text.replace('sl','\'sl\'')
	oneline_text=oneline_text.replace('cat','\'cat\'')
	oneline_text=oneline_text.replace('cot','\'cot\'')
	oneline_text=oneline_text.replace('tr','\'tr\'')
	oneline_text=oneline_text.replace('ape','\'ape\'')
	start=oneline_text.find('=')
	dic_data = ast.literal_eval(oneline_text[start+1:len(oneline_text)-1])
	table_data = np.zeros(shape=(dic_data['Summary']['total'],2))
	str_date = dic_data['Summary']['hqtime'][0:8]
	col_code = dic_data['Column']['code']
	col_tr = dic_data['Column']['tr']
	total_pages = dic_data['Summary']['pages']
	for i in range(1 , total_pages+1):
		tr_url='http://q.jrjimg.cn/?q=cn|s|sa&c=s,ta,tm,sl,cot,cat,ape&n=hqa&o=tr,d&p='+str(i)+'100&_dc=1593939870295'
		headers={'User-Agent':'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.61 Safari/537.36'}
		response=requests.get(tr_url,headers=headers)
		time.sleep(5+5*random.random())
		print('today tr data: ' + str(i)+ '-th page')
		oneline_text=response.text.replace('\n','')
		oneline_text=oneline_text.replace('\r','')
		oneline_text=oneline_text.replace(',ta:',',\'ta\':')
		oneline_text=oneline_text.replace('Summary','\'Summary\'')
		oneline_text=oneline_text.replace('Column','\'Column\'')
		oneline_text=oneline_text.replace('HqData','\'HqData\'')
		oneline_text=oneline_text.replace('mstat','\'mstat\'')
		oneline_text=oneline_text.replace('page:','\'page\':')
		oneline_text=oneline_text.replace('pages','\'pages\'')
		oneline_text=oneline_text.replace('totalh','\'totalh\'')
		oneline_text=oneline_text.replace('total:','\'total\':')
		oneline_text=oneline_text.replace('hqtime','\'hqtime\'')
		oneline_text=oneline_text.replace('id','\'id\'')
		oneline_text=oneline_text.replace('code','\'code\'')
		oneline_text=oneline_text.replace('name','\'name\'')
		oneline_text=oneline_text.replace('lcp','\'lcp\'')
		oneline_text=oneline_text.replace('stp','\'stp\'')
		oneline_text=oneline_text.replace('np','\'np\'')
		oneline_text=oneline_text.replace('tm','\'tm\'')
		oneline_text=oneline_text.replace('hlp','\'hlp\'')
		oneline_text=oneline_text.replace('pl','\'pl\'')
		oneline_text=oneline_text.replace('sl','\'sl\'')
		oneline_text=oneline_text.replace('cat','\'cat\'')
		oneline_text=oneline_text.replace('cot','\'cot\'')
		oneline_text=oneline_text.replace('tr','\'tr\'')
		oneline_text=oneline_text.replace('ape','\'ape\'')
		start=oneline_text.find('=')
		dic_data=ast.literal_eval(oneline_text[start+1:len(oneline_text)-1])
		for j in range(0,len(dic_data['HqData'])):
			rowcount = (i-1)*100 + j
			table_data[rowcount][0] = dic_data['HqData'][j][col_code]
			table_data[rowcount][1] = dic_data['HqData'][j][col_tr]
	data = pd.DataFrame({'code': table_data[:, 0], 'tr': table_data[:, 1]})
	data.to_stata('C:\\Users\\star\\Desktop\\trade\\tr_data_archive\\'+str_date+'.dta')
	data.to_excel('C:\\Users\\star\\Desktop\\trade\\tr_data_archive\\'+str_date+'.xls')

def dostata(dofile):
    ## Launch a do-file, given the fullpath to the do-file
    ## and a list of parameters.
    import subprocess    
    cmd = ['D:\\Softwares\\Stata14\\StataMP-64.exe', "do", dofile]
    return subprocess.call(cmd) 

# the lower bound of the fraction of today market maker inflow

def select_c1(today_inflow_lowerbound):
	str_date = str(datetime.datetime.utcnow()+datetime.timedelta(hours=8))[0:10]
	str_date = str_date.replace('-','')
	statacommands = ''
	statacommands = statacommands + 'cd C:\\Users\\star\\Desktop\\trade \n\
import excel inflow_data_archive\\'+str_date+'.xls, sheet(\"inflow\") firstrow clear\n\
keep code price name inflow\n\
tostring code, replace\n\
replace inflow = "" if inflow=="-"\n\
destring inflow, replace\n\
save temp.dta, replace\n\
use value_data_archive\\'+str_date+'.dta, clear\n\
drop index\n\
tostring code, replace\n\
gen l=strlen(code)\n\
replace code = \"0\"+code if l==5\n\
replace code = \"00\"+code if l==4\n\
replace code = \"000\"+code if l==3\n\
replace code = \"0000\"+code if l==2\n\
replace code = \"00000\"+code if l==1\n\
merge 1:1 code using temp.dta\n\
keep if _merge==3\n\
gen inflow_percent = 100*inflow/value\n\
gen c1=(inflow_percent>='+str(today_inflow_lowerbound)+')\n\
la var c1 "today inflow percent>1"\n\
drop l _merge\n\
drop if inflow==.\n\
save c1.dta, replace\n\
exit, clear'
	open('C:\\Users\\star\\Desktop\\trade\\dofiles\\c1.do','w').write(statacommands)
	dostata('C:\\Users\\star\\Desktop\\trade\\dofiles\\c1.do')
	c1_df = pd.read_stata('C:\\Users\\star\\Desktop\\trade\\c1.dta')
	c1_df = c1_df[c1_df.c1==1]
	return c1_df


# creteria 2 - turnover rate
# the lower bound of today_turnover/mean_turnover at (x2_1, x2_2) trading days ago
# (e.g., x2_1=20, x2_2=60, x2=2)

def append_today():
	str_date = str(datetime.datetime.utcnow()+datetime.timedelta(hours=8))[0:10]
	str_date = str_date.replace('-','')
	book = xlrd.open_workbook("C:\\Users\\star\\Desktop\\trade\\trade_days.xls").sheet_by_index(0)
	if book.cell(book.nrows-1,0).value!=int(str_date):
		book.cell(book.nrows-1,0).value=int(str_date)
		return 1
	else:
		print('Today already exists -- nothing to append')
		return 0

'''
def daysago(days_ago):
	append_today()
	book = xlrd.open_workbook("C:\\Users\\star\\Desktop\\trade\\trade_days.xls").sheet_by_index(0)
	xdays_ago = int(book.cell(book.nrows-(days_ago+1),0).value)[0:10]
	return xdays_age
'''

'''
def select_c2(x2_1,x2_2,x2):
	# min and max
	start_date = daysago(max(x2_1,x2_2))
	end_date = daysago(max(x2_1,x2_2))
	# get TR data from tushare
'''


def today_data_archive():
	print('start downloading daily inflow data')
	today_inflow_archive()
	print('inflow done')
	print('start downloading daily value data')
	today_value_archive()
	print('value done')
	print('start downloading daily turnover rate data')
	today_tr_archive()
	print('tr done')
	print('Today Data Done')

def get_today_turnover(code):
	str_date = str(datetime.datetime.utcnow()+datetime.timedelta(hours=8))[0:10]
	str_date = str_date.replace('-','')
	today_turnover_df = pd.read_stata("C:\\Users\\star\\Desktop\\trade\\tr_data_archive\\"+str_date+".dta")
	today_turnover_df = today_turnover_df[['code','tr']]
	for i in range(0,len(today_turnover_df['code'])):
		if today_turnover_df['code'].values[i] == int(code):
			return today_turnover_df['tr'].values[i]


def get_turnover_wangyi(x2_1,x2_2,x3_1,code):
# return a list: [today_turnover, mean_turnover, price at x3_1 days ago]
	tempa=min(x2_1,x2_2)
	tempb=max(x2_1,x2_2)
	x2_1=tempa
	x2_2=tempb
	length=int(1.5*max(x2_1,x2_2,x3_1))
	startdate=str(datetime.datetime.utcnow()+datetime.timedelta(hours=8)-datetime.timedelta(days=length))[0:10]
	startdate=startdate.replace('-','')
	enddate=str(datetime.datetime.utcnow()+datetime.timedelta(hours=8))[0:10]
	enddate=enddate.replace('-','')
	if code[0]=='6':
		code_wangyi='0'+code
	elif code[0]=='0' or code[0]=='3':
		code_wangyi='1'+code
	headers={'User-Agent':'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.61 Safari/537.36'}
	wangyi_url='http://quotes.money.163.com/service/chddata.html?code='+code_wangyi+'&start='+startdate+'&end='+enddate+'&fields=TURNOVER;TCLOSE'
	response_wangyi=requests.get(wangyi_url,headers=headers)
	response_wangyi_text=response_wangyi.text
	response_wangyi_text=response_wangyi_text.replace('\r','\n')
	response_wangyi_splited=response_wangyi_text.split('\n')
	for i in range(0,len(response_wangyi_splited)):
		response_wangyi_splited[i]=response_wangyi_splited[i].encode('utf-8')
	response_wangyi_splited=filter(lambda a: a != '', response_wangyi_splited)
	today_turnover = get_today_turnover(code)
	if len(response_wangyi_splited)<max(x2_1,x2_2,x3_1):
		print(code)
		print('Not enough dates -- new stock')
		return [today_turnover, np.nan, np.nan]
	elif len(response_wangyi_splited)>=max(x2_1,x2_2,x3_1):
		s=0
		for datecountback in range(x2_1,x2_2):
			s=s+float(response_wangyi_splited[datecountback].split(',')[3])
			mean_s=s/(x2_2-x2_1)
		past_price = float(response_wangyi_splited[x3_1].split(',')[4])
		print(code, mean_s, today_turnover, past_price)
		return [today_turnover, mean_s, past_price]
		

def convert_selected_dta():
	str_date = str(datetime.datetime.utcnow()+datetime.timedelta(hours=8))[0:10]
	str_date = str_date.replace('-','')
	statacommands = ''
	statacommands = statacommands + 'cd C:\\Users\\star\\Desktop\\trade\\daily_selected_dta \n\
use '+ str_date+'.dta, clear\n\
drop index \n\
merge 1:1 code using C:\\Users\\star\\Desktop\\trade\\c1.dta\n\
keep if _merge==3 \n\
keep code name value inflow today_turnover mean_turnover inflow_percent price past_price\n\
order code name price past_price value inflow today_turnover mean_turnover inflow_percent \n\
la var code "code" \n\
la var name "name" \n\
la var price "today price" \n\
la var past_price "price 20 trading days ago" \n\
replace value = value/100000000 \n\
la var value "value" \n\
replace inflow = inflow/10000 \n\
la var inflow "inflow: market maker" \n\
la var today_turnover "turnover rate today" \n\
la var mean_turnover "average turnover rate: 20-60 trading days ago" \n\
la var inflow_percent "fraction of market maker inflow" \n\
export excel using C:\\Users\\star\\Desktop\\trade\\daily_selected_xls\\'+str_date+'.xls, sheetreplace firstrow(varlabels)\n\
exit, clear'
	open('C:\\Users\\star\\Desktop\\trade\\dofiles\\convert_selected_dta.do','w').write(statacommands)
	dostata('C:\\Users\\star\\Desktop\\trade\\dofiles\\convert_selected_dta.do')

today_data_archive()

c1_df = select_c1(1)

str_date = str(datetime.datetime.utcnow()+datetime.timedelta(hours=8))[0:10]
str_date = str_date.replace('-','')

nulllist=[]
for i in range(0,len(c1_df['code'])):
	nulllist.append(np.nan)
c1_df['today_turnover'] = nulllist
c1_df['mean_turnover'] = nulllist
c1_df['past_price'] = nulllist
for i in range(0,len(c1_df['code'])):
	code = c1_df['code'].values[i]
	time.sleep(10+random.uniform(0,10))
	c2list = get_turnover_wangyi(20,60,20,code)
	c1_df.iloc[i,c1_df.columns.get_loc('today_turnover')]=c2list[0]
	c1_df.iloc[i,c1_df.columns.get_loc('mean_turnover')]=c2list[1]
	c1_df.iloc[i,c1_df.columns.get_loc('past_price')]=c2list[2]
c1_df = c1_df[['code','c1','today_turnover','mean_turnover','value','inflow','inflow_percent','price','past_price']]
print(c1_df)
c1_df.to_stata('C:\\Users\\star\\Desktop\\trade\\daily_selected_dta\\'+str_date+'.dta')

convert_selected_dta()






'''
list of varname from eastmoney
f12 code
f14 name
f2 new price
f3 price change (%)
f62 market maker - inflow
f184 f62 - %
f66 inflow today: huge order
f69 f66 - %
f72 inflow today: big order
f75 f72 - %
f78 inflow today: mid order
f81 f78 - %
f84 inflow today: small order
f87 f84 - %
'''

'''
http://quotes.money.163.com/service/chddata.html?code=[code]&start=[startdate]&end=[enddate]&fields=[fields]
TCLOSE
HIGH
LOW
TOPEN
LCLOSE
CHG
PCHG
TURNOVER
VOTURNOVER
VATURNOVER
TCAP
MCAP

'''
