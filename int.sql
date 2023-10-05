select *from clienti



	INTEROGARI
	----------------------------------------------------------------
	--Liță Cosmin-Constantin
	
	--  1) grupare si filtrare
	--Care sunt clientii care au cumparat fuste si cate bucati li s-a livrat efectiv?
	--		adica (doar comenzile EFECTUATE) cu status_produs='in stoc'

	SELECT cl.id_client,COUNT(pd.cod_tip_produs) AS numar_fuste
	FROM clienti cl INNER JOIN comenzi_preluate cp ON cl.id_client=cp.id_client
	INNER JOIN detalii_comenzi dc ON cp.id_comanda=dc.id_comanda
	INNER JOIN produse pd ON dc.id_produs=pd.id_produs
	INNER JOIN tip_produs tp ON pd.cod_tip_produs=tp.cod_tip_produs
	WHERE tp.descriere_produs='fusta' AND cp.status_comanda='efectuata' AND status_produs='in stoc'
	GROUP BY cl.id_client

	-- 2) subconsultari in clauza HAVING 
	--interogari ajutatoare
	-- numarul de blugi in stoc -7 bucati

	SELECT tp.descriere_produs,COUNT(pd.cod_tip_produs)
	FROM tip_produs tp INNER JOIN produse pd on tp.cod_tip_produs=pd.cod_tip_produs
	WHERE  tp.descriere_produs='blugi'  
	GROUP BY tp.descriere_produs
	--numarul de blugi vanduti efectiv
	--status comanda trebuie sa fie EFECTUAT pentru ca nu poti vinde un produs daca comanda este anulata 
	SELECT tp.descriere_produs,COUNT(pd.cod_tip_produs)
	FROM tip_produs tp INNER JOIN produse pd ON tp.cod_tip_produs=pd.cod_tip_produs
	INNER JOIN detalii_comenzi dc ON pd.id_produs=dc.id_produs
	INNER JOIN comenzi_preluate cp ON dc.id_comanda=cp.id_comanda
	WHERE  tp.descriere_produs='blugi' AND  status_comanda='efectuata' 
	GROUP BY tp.descriere_produs
	
	--REZOLVARE
	--CERINTA:Care este tipul produselor vandute intr-un numar mai mare decat blugii?
	--status comanda trebuie sa fie efectuat pentru ca nu poti vinde un produs daca comanda este anulata 

	SELECT tp.descriere_produs,count(descriere_produs) AS numar_prod
	FROM  tip_produs tp INNER JOIN produse pd ON tp.cod_tip_produs=pd.cod_tip_produs
	INNER JOIN detalii_comenzi dc ON pd.id_produs=dc.id_produs
	INNER JOIN comenzi_preluate cp ON dc.id_comanda=cp.id_comanda
	WHERE status_comanda='efectuata'
	GROUP BY tp.descriere_produs
	HAVING COUNT(descriere_produs)>(SELECT COUNT(pd.cod_tip_produs)
								FROM  tip_produs tp INNER JOIN produse pd ON tp.cod_tip_produs=pd.cod_tip_produs
								INNER JOIN detalii_comenzi dc ON pd.id_produs=dc.id_produs
								INNER JOIN comenzi_preluate cp ON dc.id_comanda=cp.id_comanda
								WHERE  tp.descriere_produs='blugi' AND  status_comanda='efectuata' 
	)

	-- 3) tabele pivot 

	--id client+nume
	SELECT id_client_pf,clienti_pf.nume_pf ||'-'||clienti_pf.prenume_pf
	FROM clienti INNER JOIN clienti_pf ON clienti.id_client=clienti_pf.id_client_pf

	-- REZOLVARE primele 3 tipuri de produse livrate catre fiecare client(indiferent daca este persoana fizica sau juridica) si numarul total de produse comandate pana atunci

	with primele_3_produse AS ( SELECT cp.id_client,descriere_produs, pd.nume_prod,ROW_NUMBER() OVER(PARTITION BY cp.id_client ORDER BY cp.id_client) AS nprod
							  FROM comenzi_preluate cp INNER JOIN detalii_comenzi dc ON cp.id_comanda=dc.id_comanda 
						  INNER JOIN produse pd ON dc.id_produs=pd.id_produs 
						   INNER JOIN tip_produs tp ON pd.cod_tip_produs=tp.cod_tip_produs ),
							  total AS (SELECT 'VT=valoare_totala', ' ', ' ', ' ',  
							SUM(COUNT(*)) OVER() AS total FROM detalii_comenzi)
							  SELECT * 
							  FROM (
								  SELECT cp.id_client ,
								  Coalesce (nprod1.descriere_produs,'') AS produs1,
								  Coalesce (nprod2.descriere_produs,'') AS produs2,
								  Coalesce (nprod3.descriere_produs,'') AS produs3,
								  	COUNT (*) AS Total_nr_produse
								  
								   FROM comenzi_preluate cp inner join detalii_comenzi dc on cp.id_comanda=dc.id_comanda 
						   INNER JOIN  produse pd on dc.id_produs=pd.id_produs 
						   INNER JOIN  tip_produs tp on pd.cod_tip_produs=tp.cod_tip_produs 
								   LEFT OUTER JOIN primele_3_produse nprod1 on cp.id_client=nprod1.id_client and nprod1.nprod=1
								   LEFT OUTER JOIN primele_3_produse nprod2 on cp.id_client=nprod2.id_client and nprod2.nprod=2
								    LEFT OUTER JOIN primele_3_produse nprod3 on cp.id_client=nprod3.id_client and nprod3.nprod=3
								  group by  nprod1.descriere_produs,nprod2.descriere_produs,nprod3.descriere_produs,cp.id_client
							  )y
							 UNION
							 SELECT *
							  FROM total
							 ORDER BY 1

	-- REZOLVARE ALT EXERCITIU: primele 3 produse din fiecare comanda comandate de fiecare CLIENT PERSOANA FIZICA,-cu numele ei concaternat 
	--  numarul total de produse comandate pana atunci de la noi, TOTALUL trebuie sa ne dea numarul total de produse comandate de toti clientii persoane fizice
	
	with primele_3_produse as ( SELECT dc.id_comanda,cf.id_client_pf,descriere_produs, pd.nume_prod,row_number() over(partition by cf.id_client_pf order by cf.id_client_pf) as 	nprod,cf.nume_pf||'-'||cf.prenume_pf as nume_pf
							   from clienti_pf cf INNER JOIN clienti cl on cf.id_client_pf=cl.id_client INNER JOIN comenzi_preluate cp on 	cl.id_client=cp.id_client INNER JOIN detalii_comenzi dc on cp.id_comanda=dc.id_comanda 
						 INNER JOIN produse pd on dc.id_produs=pd.id_produs 
						   INNER JOIN tip_produs tp on pd.cod_tip_produs=tp.cod_tip_produs ),
							  total AS (SELECT 'VT=valoare_totala', ' ', ' ', ' ',' ',  
							SUM(COUNT(*)) OVER() AS total from clienti_pf cf INNER JOIN clienti cl on cf.id_client_pf=cl.id_client INNER JOIN comenzi_preluate cp 	on cl.id_client=cp.id_client 
										INNER JOIN detalii_comenzi dc on cp.id_comanda=dc.id_comanda 
						   INNER JOIN produse pd on dc.id_produs=pd.id_produs 
						  INNER JOIN tip_produs tp on pd.cod_tip_produs=tp.cod_tip_produs )
							  SELECT * 
							  from (
								 SELECT dc.id_comanda,cf.nume_pf||'-'||cf.prenume_pf as nume_pf,
								  Coalesce (nprod1.descriere_produs,'') as produs1,
								  Coalesce (nprod2.descriere_produs,'') as produs2,
								  Coalesce (nprod3.descriere_produs,'') as produs3,
								  	COUNT (*) AS Total_nr_produse
								  
								     FROM clienti_pf cf INNER JOIN clienti cl on cf.id_client_pf=cl.id_client INNER JOIN comenzi_preluate cp on 	cl.id_client=cp.id_client inner join detalii_comenzi dc on cp.id_comanda=dc.id_comanda 
						  INNER JOIN produse pd on dc.id_produs=pd.id_produs 
						   INNER JOIN tip_produs tp on pd.cod_tip_produs=tp.cod_tip_produs
								   LEFT OUTER JOIN primele_3_produse nprod1 on cp.id_client=nprod1.id_client_pf and nprod1.nprod=1
								   LEFT OUTER JOIN primele_3_produse nprod2 on cp.id_client=nprod2.id_client_pf and nprod2.nprod=2
								    LEFT OUTER JOIN primele_3_produse nprod3 on cp.id_client=nprod3.id_client_pf and nprod3.nprod=3
								 GROUP BY  nprod1.descriere_produs,nprod2.descriere_produs,nprod3.descriere_produs,cf.nume_pf||'-'||	cf.prenume_pf,dc.id_comanda
							  )y
							  union 
							 SELECT *
							  from total
							  order by 1
							  

	--4) interogare pseudo-recursiva
	--CERINTA:Sa se numeroteze toate produsele de pe fiecare comanda a clientilor

	WITH produse AS
	(SELECT comenzi_preluate.id_comanda,comenzi_preluate.id_client,
		ROW_NUMBER() OVER (PARTITION BY comenzi_preluate.id_comanda ORDER BY comenzi_preluate.id_comanda) AS numar_prod,
		produse.nume_prod AS nume_prod
	 FROM comenzi_preluate
		INNER JOIN detalii_comenzi on comenzi_preluate.id_comanda=detalii_comenzi.id_comanda
		INNER JOIN produse on detalii_comenzi.id_produs=produse.id_produs
	)
	SELECT id_comanda,id_client,
	string_agg(DISTINCT CAST(RIGHT(' ' || numar_prod,2) || ':' || nume_prod AS VARCHAR), '; '
							 ORDER BY CAST(RIGHT(' ' || numar_prod,2) || ':' || nume_prod AS VARCHAR))
							 AS toate_produsele
	FROM produse
	GROUP BY id_comanda,id_client



	

	--1)grupare si filtrare
	--Cate metode de plata au ales clientii din judetul Galati?

	select cmp.id_client, count(distinct(cmp.cod_met_plata)) as numar_met_plata
	from clienti cl inner join clienti_metoda_de_plata cmp on cl.id_client=cmp.id_client
	inner join metode_de_plata mp on cmp.cod_met_plata=mp.cod_met_plata
	where cl.jud='Galati'
	group by  cmp.id_client

	--Cate comenzi are fiecare angajat?
	select ang.nume_angajat,count(id_comanda) as numar_comenzi
	from angajati ang inner join comenzi_preluate cp on ang.id_angajat=cp.id_angajat
	group by ang.nume_angajat
	order by numar_comenzi desc

	--2)subconsultari in clauza HAVING 
	----Care sunt angajatii care au preluat mai multe comenzi decat Toader Andreea?
	select ang.nume_angajat  --,count(id_comanda) as numar_comenzi-cu aceasta completare avem si numarul de comenzi
	from angajati ang inner join comenzi_preluate cp on ang.id_angajat=cp.id_angajat
	group by ang.nume_angajat
	having count(id_comanda)>( select count(id_comanda)
						  from angajati ang inner join comenzi_preluate cp on ang.id_angajat=cp.id_angajat
						where ang.nume_angajat='Toader Andreea'
	)
	--3)tabele pivot
	--aflati numarul platii si sumele pentru anii 2018,2019,2020 si totalul general pe ani
	WITH
	vanzari2018 AS (SELECT cp.id_client, SUM(suma_plata) AS vanzari
		 	 FROM plati pl inner join facturi fct on pl.numar_fact=fct.numar_fact
					inner join comenzi_preluate cp on fct.id_comanda=cp.id_comanda
		 	 WHERE EXTRACT (YEAR FROM data_plata) = 2018
		 	 GROUP BY cp.id_client),
	vanzari2019 AS (SELECT cp.id_client, SUM(suma_plata) AS vanzari
		 	 FROM plati pl inner join facturi fct on pl.numar_fact=fct.numar_fact
					inner join comenzi_preluate cp on fct.id_comanda=cp.id_comanda
		 	 WHERE EXTRACT (YEAR FROM data_plata) = 2019
		 	 GROUP BY cp.id_client),
	vanzari2020 AS (SELECT cp.id_client, SUM(suma_plata) AS vanzari
		 	 FROM plati pl inner join facturi fct on pl.numar_fact=fct.numar_fact
					inner join comenzi_preluate cp on fct.id_comanda=cp.id_comanda
		 	 WHERE EXTRACT (YEAR FROM data_plata) = 2020
		 	 GROUP BY cp.id_client),
	vanzari2018_2020 AS
			(
			SELECT 'TOTAL',
				(SELECT SUM(suma_plata)
				 FROM plati
				 WHERE EXTRACT (YEAR FROM data_plata) = 2018  ) as vanzari2018,
				(SELECT SUM(suma_plata)
				 FROM plati
				 WHERE EXTRACT (YEAR FROM data_plata) = 2019  ) as vanzari2019,
				(SELECT SUM(suma_plata)
				 FROM plati
				 WHERE EXTRACT (YEAR FROM data_plata) = 2020  ) as vanzari2020
			)
	SELECT 1 AS ordine, x.*
	FROM
	(SELECT comenzi_preluate.id_client AS clienti,
		COALESCE(vanzari2018.vanzari, 0) AS vanzari2018,
		COALESCE(vanzari2019.vanzari, 0) AS vanzari2019,
		COALESCE(vanzari2020.vanzari, 0) AS vanzari2020
	FROM comenzi_preluate 
		LEFT JOIN vanzari2018 ON comenzi_preluate.id_client = vanzari2018.id_client
		LEFT JOIN vanzari2019 ON comenzi_preluate.id_client = vanzari2019.id_client
		LEFT JOIN vanzari2020 ON comenzi_preluate.id_client = vanzari2020.id_client ) x
	UNION 
	SELECT 2, vanzari2018_2020.*
	FROM vanzari2018_2020
	ORDER BY ordine

	--4)sa se afle sumele de plata pentru fiecare client
	select id_client, string_agg(plati.numar_fact||'('||plati.suma_plata||')',',')as facturi_sume
	from comenzi_preluate
	inner join facturi on comenzi_preluate.id_comanda=facturi.id_comanda
	inner join plati on facturi.numar_fact=plati.numar_fact
	group by id_client
	order by id_client



	--1) Afisati numarul clientilor de gen feminin din Romania grupati pe orase.

 	SELECT clienti.oras, COUNT(clienti.id_client)  as Nr_Client
	FROM clienti
	INNER JOIN clienti_pf ON clienti.id_client = clienti_pf.id_client_pf
	WHERE clienti.tara = 'Romania' and clienti_pf.gen='F'
	GROUP BY clienti.oras
	ORDER BY clienti.oras

	--2)Ce facturi s-au emis in prima luna calendaristica a vanzarilor ?

	SELECT *
	FROM facturi
	WHERE EXTRACT (YEAR FROM data_fact) || '-' || EXTRACT (MONTH FROM data_fact) + 100 IN
	(SELECT MIN(EXTRACT (YEAR FROM data_fact) || '-' || 100 + EXTRACT (MONTH FROM data_fact)) --selecteaza prima luna cu vanzari
	  FROM facturi)
	  
	--3)Care sunt clientii care au mai putine comenzi date decat clientul 1230?
	WITH numar_comenzi AS (
	SELECT COUNT(*) AS nr_comenzi
	FROM comenzi_preluate
	WHERE comenzi_preluate.id_client ='1230')
	SELECT id_comanda, COUNT(*) AS n_de_comenzi
	FROM comenzi_preluate
	WHERE comenzi_preluate.id_client ='1230'
	GROUP BY id_comanda
	HAVING COUNT(*) < (SELECT nr_comenzi FROM numar_comenzi)

	--4)Sa se afle produsele cu discount din fiecare comanda
	select id_comanda, string_agg(nume_prod||'('||discount||')',',')as facturi_sume
	from detalii_comenzi
	inner join produse on detalii_comenzi.id_produs=produse.id_produs
	inner join discount on produse.id_produs=discount.id_produs_disc
	group by id_comanda
	order by id_comanda


