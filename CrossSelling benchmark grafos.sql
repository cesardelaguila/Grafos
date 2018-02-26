--recomendacion para campaña 201711
-- va a ver que paso en 201710, AnioCampanaProceos

drop table #concat
select Izquierda, Derecha, Perfil, Izquierda+Derecha as tupla, Soporte, Confianza, Lift into #concat
from BD_ANALITICO.DBO.MDL_AsociacionOutput
where codpais = 'CL' AND AnioCampanaProceso = '201710' AND lift > 1 and confianza > 0.1
order by izquierda, Perfil
select * from #concat
--25933

drop table #conteo
select tupla, count(tupla) as counts into #conteo
from #concat
group by tupla
--(8932 row(s) affected)

drop table #RecomGeneral
select * into #RecomGeneral 
from #conteo 
where counts = 6

select * from #RecomGeneral
-- sin ponerle scores todavia. porque a la hora de poner, se saca promedios y puede ser distorsionado

--drop table #RecomConScore
--select a.tupla, avg(Soporte) as Soporte, avg(Confianza) as Confianza, avg(Lift) as Lift
--into #RecomConScore
-- from #RecomGeneral a 
--inner join #concat b on a.tupla = b.tupla
--group by a.tupla


--drop table CF_RecomFinal
--select distinct b.Izquierda, b.Derecha, a.Soporte, a.Confianza, a.Lift 
--into CF_RecomFinal
--from #RecomConScore a
--inner join #concat b on a.tupla = b.tupla


drop table #CF_RecomFinal_SN
select distinct b.Izquierda, b.Derecha, a.tupla
into #CF_RecomFinal_SN
from #RecomGeneral a
inner join #concat b on a.tupla = b.tupla

select * from #CF_RecomFinal_SN


DROP TABLE #CUC
select PkProducto, DesProductoCUC, '{'+cast(CodCUC as varchar)+'}' as CUC, DesSubCategoria
into #CUC
from  DWH_ANALITICO.dbo.DWH_DPRODUCTO 
where CodPais = 'CL' 
and DesCategoria in  ('fragancias')
and DesMarca in ('ESIKA')
and CodCUC <> '' and CodCUC is not null
--(15765 row(s) affected)





drop table #CF_RecomFinal_CN1
select b.Izquierda, a.DesProductoCUC as compro, DesSubCategoria as SubCategoria, Derecha, tupla
into #CF_RecomFinal_CN1
from #CUC a inner join #CF_RecomFinal_SN b on a.CUC = b.Izquierda 
select * from #CF_RecomFinal_CN1

drop table #CF_RecomFinal_CN2
select b.Izquierda, b.compro, b.SubCategoria, b.Derecha, a.DesProductoCUC as recomendar, DesSubCategoria
into #CF_RecomFinal_CN2
from #CUC a inner join #CF_RecomFinal_CN1  b on a.CUC = b.Derecha

select distinct * 
into #CF_RecomFinal_
from #CF_RecomFinal_CN2

select * from #CF_RecomFinal_


--obtenemos la venta de las exitosas
drop table #PkMuestra
select distinct a.PkEbelista into #PkMuestra
from NUEVASG a 
where a.TargetExito = 1

drop table #Vta_sinPK
select PKEbelista, PKProducto 
into #Vta
from DWH_ANALITICO.dbo.DWH_FVTAPROEBECAM
where CodPais = 'CL' and AnioCampana = AnioCampanaRef and AnioCampana = '201710'
and PKEbelista in (select PkEbelista FROM #PkMuestra)

drop table #Vta_conPK
select distinct a.PKEbelista, a.PKProducto, b.CUC, b.DesProductoCUC, b.DesSubCategoria
into #Vta_conPK
from #Vta a
INNER JOIN #CUC b on a.PKProducto = b.PKProducto
order by b.CUC

select  * from #Vta_conPK
where PKEbelista ='653313'


select * from #CF_RecomFinal_

drop table #Recom_Consultora
select a.PKEbelista, a.PKProducto, a.CUC as izquierda, b.compro, b.SubCategoria, Derecha, recomendar, b.DesSubCategoria
into #Recom_Consultora
from #Vta_conPK a inner join #CF_RecomFinal_ b on b.Izquierda = a.CUC
order by CUC

select izquierda, compro, SubCategoria, derecha, recomendar, DesSubCategoria, count(PKEbelista) as veces_recomendado
from #Recom_Consultora
group by  izquierda, compro, SubCategoria, derecha, recomendar, DesSubCategoria
order by izquierda



--agregar columna lift, confianza, soporte.
-- contar repeticion de las tuplas. 