--recomendacion para campaña 201711
-- va a ver que paso en 201710, AnioCampanaProceos

drop table #concat
select Izquierda, Derecha, Perfil, Izquierda+Derecha as tupla, Soporte, Confianza, Lift into #concat
from BD_ANALITICO.DBO.MDL_AsociacionOutput
where codpais = 'CL' AND AnioCampanaProceso = '201710' AND lift > 1 and confianza > 0.1
order by izquierda, Perfil

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

drop table #RecomFinal
select distinct b.Izquierda, b.Derecha, a.Soporte, a.Confianza, a.Lift 
into #RecomFinal
from #RecomConScore a
inner join #concat b on a.tupla = b.tupla

select * from #RecomFinal

select * from DWH_ANALITICO.dbo.DWH_FVTAPROEBECAM
where AnioCampana = '201710' and CodPais = 'CL'





-- BD_ANALITICO.DBO.MDL_PerfilOutput 