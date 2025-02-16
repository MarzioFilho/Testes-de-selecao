--1A
--Alguns registros de source tem valores muito, mas assim, muito diferentes da média, 
--isso as fazem tornarem outliers e atrapalharem o cálculo, fazendo parecer valores impraticáveis
select
	ifnull(atv.Empresa, 'Grupo Econômico') as Empresa,
	sum(atv.totalAtv) as TotalAtv,
	sum(pass.totalPass) as TotalPsv,
	sum(atv.totalAtv) + sum(pass.totalPass) as checkIntegridade
from
	(
		select
			emp.name as Empresa,
			sum(convert(src.value, decimal(10,2))) as totalAtv
		from
			source src
		inner join
			centro_custo cc
			on
				cc.code = src.code_centro_custo
		inner join
			empresa emp
			on
				emp.code = src.code_empresa
		where
			convert(src.code, unsigned) = 1
		and
			month(convert(src.data, date)) = 1 
		and
			cc.sn_ativo = 'S'
		group by emp.name
	) atv
inner join
	(
		select
			emp.name as Empresa,
			sum(convert(src.value, decimal(10,2))) as totalPass
		from
			source src
		inner join
			centro_custo cc
			on
				cc.code = src.code_centro_custo
		inner join
			empresa emp
			on
				emp.code = src.code_empresa
		where
			convert(src.code, unsigned) > 1
		and
			month(convert(src.data, date)) = 1 
		and
			cc.sn_ativo = 'S'
		group by emp.name
	) pass
	on
		atv.Empresa = pass.Empresa
group by
	atv.Empresa with rollup
	
________________________________________


--1B
SET sql_mode = CONCAT(@@sql_mode, ',IGNORE_SPACE');

set 
	@jsonbc=
	(
		json_object
		(
			"Grupo Econômico",
			(
				select 
					json_arrayagg
					(
						json_object
						(
							"Total Ativos", atv.totalAtv,
							"Total Passivos", pass.totalPass,
							"Check Integridade", (atv.totalAtv + pass.totalPass)
						)
					)
				from
				(
					select 
						sum(convert(src.value, decimal(10,2))) as totalAtv
					from
						source src
					inner join
						centro_custo cc
						on	
							cc.code = src.code_centro_custo
					where
						convert(src.code, unsigned) = 1
						and	
							month(convert(src.data, date)) = 1 
						and	
							cc.sn_ativo = "S"
				) atv
				inner join
				(
					select
						sum(convert(src.value, decimal(10,2))) as totalPass
					from
						source src
					inner join
						centro_custo cc
						on	
							cc.code = src.code_centro_custo
					where
						convert(src.code, unsigned) > 1
						and	
							month(convert(src.data, date)) = 1 
						and	
							cc.sn_ativo = "S"
				) pass
				on	
					1 = 1
			),
			"Detalhamento Check Integridade",
			(
				select	
					json_arrayagg
					(
						json_object
						(
							"Empresa", atv.Empresa,
							"Total de Ativos", atv.totalAtv,
							"Total de Passivos", pass.totalPass,
							"Check de Integridade", (atv.totalAtv + pass.totalPass)
						)
					)
				from
				(
					select
						emp.name as Empresa,
						sum(convert(src.value, decimal(10,2))) as totalAtv
					from	
						source src
					inner join
						centro_custo cc
						on	
							cc.code = src.code_centro_custo
					inner join
						empresa emp
						on	
							emp.code = src.code_empresa
					where
						convert(src.code, unsigned) = 1
						and	
							month(convert(src.data, date)) = 1 
						and	
							cc.sn_ativo = 'S'
					group by	
						emp.name
					order by	
						emp.name asc
				) atv
				inner join
				(
					select
						emp.name as Empresa,
						sum(convert(src.value, decimal(10,2))) as totalPass
					from	
						source src
					inner join
						centro_custo cc
						on	
							cc.code = src.code_centro_custo
					inner join
						empresa emp
						on	
							emp.code = src.code_empresa
					where
						convert(src.code, unsigned) > 1
						and	
							month(convert(src.data, date)) = 1 
						and	
							cc.sn_ativo = 'S'
					group by	
						emp.name
					order by	
						emp.name asc
				) pass
				on	
					atv.Empresa = pass.Empresa
			)
		)
	);

select json_pretty(@jsonbc);

________________________________________


--2A
select 
	pr.descricaopredio as descricao,
	count(sa.numsala) as quantidadeSala
from 
	predio pr
inner join
	sala sa
	on
		pr.codpredio = sa.codpredio
group by 
	pr.descricaopredio
having
	count(sa.numsala) > 3
order by
	pr.descricaopredio;
	
________________________________________


--2B
select
	disc.nomedisc as nomeDisciplina,
	ptur.siglatur as siglaTurma
from
	profturma ptur
inner join
	disciplina disc
	on
		ptur.numdisc = disc.numdisc
inner join
	professor prof
ON
	ptur.codprof = prof.codprof
where
	prof.nomeprof = "Tavares"
	
________________________________________


--2C
set 
	@jsonprof=
	(
		select
			json_arrayagg
			(
				json_object
				(
					"Nome Professor",
					prof.nomeprof,
					"Turmas",
					json_object
					(
						"Ano Semestre Turma", tur.anosem,
						"Sigla Turma", tur.siglatur,
						"Capacidade Turma", tur.capacidade,
						"Nome Disciplina", disc.nomedisc,
						"Descrição Prédio", pre.descricaopredio,
						"Número Sala", sal.numsala,
						"Dias Horários",
						json_object
						(
							"Dia Semana", hor.diasem,
							"Horário Início", hor.horainicio
						)
					)
				)
			)
		from
			disciplina disc
		inner join
			turma tur
			on
				disc.numdisc = tur.numdisc
		inner join
			profturma ptur
			on
				tur.siglatur = ptur.siglatur
		inner join
			professor prof
			on
				prof.codprof = ptur.codprof
		inner join
			horario hor
			on
				tur.siglatur = hor.siglatur
		inner join
			sala sal
			on
				sal.numsala = hor.numsala
		inner join
			predio pre
			on
				pre.codpredio = sal.codpredio
	);
	
select json_pretty(@jsonprof);