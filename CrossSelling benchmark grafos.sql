--recomendacion para campaña 201711
-- va a ver que paso en 201710, AnioCampanaProceos

drop table #concat
select Izquierda, Derecha, Perfil, Izquierda+Derecha as tupla, Soporte, Confianza, Lift into #concat
from BD_ANALITICO.DBO.MDL_AsociacionOutput
where codpais = 'CL' AND AnioCampanaProceso = '201710' AND lift > 1 and confianza > 0.1
order by izquierda, Perfil
select * from #concat

drop table #conteo
select tupla, count(tupla) as counts into #conteo
from #concat
group by tupla

drop table #RecomGeneral
select * into #RecomGeneral 
from #conteo 
where counts = 6

drop table #RecomConScore
select a.tupla, avg(Soporte) as Soporte, avg(Confianza) as Confianza, avg(Lift) as Lift
into #RecomConScore
 from #RecomGeneral a 
inner join #concat b on a.tupla = b.tupla
group by a.tupla

drop table CF_RecomFinal
select distinct b.Izquierda, b.Derecha, a.Soporte, a.Confianza, a.Lift 
into CF_RecomFinal
from #RecomConScore a
inner join #concat b on a.tupla = b.tupla

select * from CF_RecomFinal


-----aca es para crucar con las consultoras. falta saber que codigo es el que muesra  el cross selling


DROP TABLE #CUC
select PkProducto, '{'+cast(CodCUC as varchar)+'}' as CUC, DesCategoria, DesSubCategoria into #CUC
from  DWH_ANALITICO.dbo.DWH_DPRODUCTO 
where CodPais = 'CL' 
and DesCategoria in ('tratamiento corporal', 'tratamiento facial', 'cuidado personal', 'maquillaje', 'fragancias')
and CodCUC <> '' and CodCUC is not null
--(15765 row(s) affected)




drop table #PkNuevas
select distinct PkEbelista  into #PkNuevas
FROM [DWH_ANALITICO].[dbo].[DWH_FSTAEBECAM]
where CodComportamientoRolling = 1 and CodPais = 'CL' and AnioCampana = '201710'


drop table CF_RecomFinal_Consultoras
select CodPais, AnioCampana,  a.PKEbelista, a.PKProducto, c.CUC as CUC_0, d.Derecha AS CUC_1 , c.DesCategoria, c.DesSubCategoria, RealUUVendidas, RealVtaMNNeto
into CF_RecomFinal_Consultoras
FROM DWH_ANALITICO.dbo.DWH_FVTAPROEBECAM a 
INNER JOIN #PkNuevas b on a.PkEbelista = b.PkEbelista and CodPais = 'CL' and AnioCampana = '201710'
inner join #CUC c on a.PkProducto = c.PKProducto and CodPais = 'CL' 
inner join CF_RecomFinal d on c.CUC = d.Izquierda 

select top (1000) * from CF_RecomFinal_Consultoras
