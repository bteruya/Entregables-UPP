*************************************************
*Project:		Producto 1  					*
*Institution:	MINEDU             				*
*Author:		Brenda Teruya					*
*Last edited:	2019-10-04          			*
*************************************************


glo dd "C:\Users\analistaup2\Google Drive\Trabajo\MINEDU_trabajo\UPP\Actividades\Focalizacion"
set excelxlsxlargefile on
cd "$dd\datos"

********************************************************************************
*Bases de datos

import excel "DIGEBR\Padron - Wiñaq.xlsx", ///
sheet("PADRON DEPORTIVOS_ESCUELAS") cellrange(A1:Y201) firstrow clear
destring MODULAR, gen(cod_mod)
gen anexo = 0

tempfile winaq
save `winaq'

import excel "DIGEBR\Padron - EXPRESARTE.xlsx", ///
 sheet("Padrón 2019 (RM083-2019)") firstrow clear
count 

destring CODIGOMODULAR, gen(cod_mod)
gen anexo = 0
tempfile expresarte
save `expresarte'

import excel "DIGEBR\Padron - Orquestando.xlsx", sheet("1.12 Orquestando") ///
cellrange(A3:G16) firstrow clear

destring CódigoModular, gen(cod_mod)
gen anexo = 0
tempfile orquestando
save `orquestando'


import excel "DISER\MSE Padrones 2020_20092019.xlsx", sheet("ST 36") ///
	cellrange(A4:O40) firstrow clear
replace CODIGOMODULAR = "" if CODIGOMODULAR == "EN TRÁMITE"
destring CODIGOMODULAR, gen(cod_mod)
replace cod_mod = _n if cod_mod == .
rename COMUNIDADNÚCLEO comunidad_nucleo
gen anexo = 0
tempfile st2020
save `st2020'

import excel "DISER\MSE Padrones 2020_20092019.xlsx", sheet("SRE 77") ///
	cellrange(A3:R80) firstrow clear
destring COD_MOD , gen(cod_mod)
gen anexo = 0

tempfile sre2020_77
save `sre2020_77'
*AP SRE

import excel "DISER\MSE Padrones 2020_20092019.xlsx",  sheet("SA 78") cellrange(A1:K79) firstrow clear
destring CódigomodulardeCRFA , gen(cod_mod)
gen anexo = 0

tempfile crfa2020
save `crfa2020'


import excel "DIGESE\Email 04oct19\METAS DE ATENCION EBE_SECCIONES.xlsx", sheet("CEBE") ///
 cellrange(A3:R394) firstrow clear
drop if COD_LOCAL == ""
isid COD_LOCAL 
rename COD_LOCAL codlocal 
tempfile cebe
save `cebe'


import excel "DIGESE\Email 04oct19\METAS DE ATENCION EBE_.xlsx", sheet("PRITE") ///
 cellrange(A3:M106) firstrow clear
destring COD_MOD, gen(cod_mod)
gen anexo = 0
tempfile prite
save `prite'

import excel "DIGESE\Email 04oct19\METAS DE ATENCION EBE_.xlsx", sheet("CREBE") ///
 cellrange(A3:M28) firstrow clear
tempfile crebe
save `crebe'



********************************************************************************
*contar numero de intervenciones por IE

use "BasePuraIntegrada.dta", clear
keep if estado == "1" //activas


merge 1:1 cod_mod anexo using `winaq', keepusing(D_REGION)
gen winaq = _m == 3
drop _m
label var winaq "La IE tiene winaq"
label def winaq 0 "No winaq" 1 "Si Winaq"
label val winaq winaq

codebook winaq

merge 1:1 cod_mod anexo using `expresarte', keepusing(DEPARTAMENTO)
gen expresarte = _m == 3
drop _m
label var expresarte "La IE tiene expresarte"
label def expresarte 0 "No expresarte" 1 "Si expresarte"
label val expresarte expresarte

codebook expresarte

merge 1:1 cod_mod anexo using  `orquestando', keepusing(DREUGEL)
gen orquestando = _m == 3
drop _m
label var orquestando "La IE tiene orquestando"
label def orquestando 0 "No orquestando" 1 "Si orquestando"
label val orquestando orquestando

codebook orquestando

merge 1:m cod_mod anexo using  `st2020', ///
keepusing(REGIÓN)
* hay dos o más SRE con el mismo codmod provisional
gen st = _m != 1

drop _m
label var st "La IE tiene st"
label def st 0 "No st" 1 "Si st"
label val st st

codebook st
bys cod_mod anexo: egen n_st = sum(st)
label var n_st "N. de ST en cada codmod"
duplicates drop cod_mod anexo, force
tabstat n_st, stat(sum)


merge 1:1 cod_mod anexo using  `sre2020_77' , keepusing(D_DPTO)
gen sre = _m == 3
drop _m
label var sre "La IE tiene sre"
label def sre 0 "No sre" 1 "Si sre"
label val sre sre

codebook sre

merge 1:1 cod_mod anexo using  `crfa2020', keepusing(Ugel)
gen crfa = _m == 3
drop _m
label var crfa "La IE tiene crfa"
label def crfa 0 "No crfa" 1 "Si crfa"
label val crfa crfa

codebook crfa

merge m:1 codlocal using `cebe', keepusing(REGIÓN)
gen cebe = _m != 1
label var cebe "La IE tiene cebe"
label def cebe 0 "No cebe" 1 "Si cebe"
label val cebe cebe
replace cod_mod = _n if _m == 2
replace anexo = 0 if _m == 2
drop _m

codebook cebe

merge 1:1 cod_mod anexo using  `prite', keepusing(REGIÓN)
gen prite = _m == 3
drop _m
label var prite "La IE tiene prite"
label def prite 0 "No prite" 1 "Si prite"
label val prite prite

codebook prite

merge m:1 codlocal using `crebe', keepusing(D_REGION)
gen crebe = _m != 1
drop _m
label var crebe "La IE tiene crebe"
label def crebe 0 "No crebe" 1 "Si crebe"
label val crebe crebe

codebook crebe

replace d_region = D_REGION if d_region == ""
replace d_region = REGIÓN if d_region == ""
tab d_region

replace d_region = "DRE PASCO" if d_region == "PASCO"
replace d_region = "DRE PIURA" if d_region == "PIURA"
replace d_region = "DRE TUMBES" if d_region == "TUMBES"
replace d_region = "DRE LIMA PROVINCIAS" if d_region == "LIMA"

export excel cod_mod codlocal winaq expresarte orquestando n_st sre crfa cebe prite crebe ///
using "Data sets Intermedios\Entregable1.xlsx", sheet("cod_mod", replace) firstrow(varlabels)
 
collapse (sum) winaq expresarte orquestando n_st sre crfa cebe prite crebe ///
, by(d_region)

foreach var in winaq expresarte orquestando n_st sre crfa cebe prite crebe {

label var `var' "N. de cod_mod con intervencion `var'"
}

export excel  ///
using "Data sets Intermedios\Entregable1.xlsx", sheet("dre", replace) firstrow(variables)
 
