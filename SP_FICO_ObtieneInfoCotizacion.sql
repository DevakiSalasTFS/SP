USE [BD_Cot4]
GO
/****** Object:  StoredProcedure [dbo].[FICO_ObtieneInfoCotizacion]    Script Date: 10/09/2018 10:24:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Miguel Rivas>
-- Create date: <12/12/2017>
-- Description:	<Obtiene informacion de cotización>
-- =============================================
ALTER PROCEDURE [dbo].[FICO_ObtieneInfoCotizacion] 
	@idCotizacion AS INT
AS
BEGIN


EXEC	[dbo].[AgregaPoliza]
		@ID_COTIZACION = @idCotizacion;
		
SELECT 
	distribuidor.bid dis_matriz,
	distribuidor.bid2 dis_matriz2,
	distribuidor.descripcion dis_descripcion,
	estado.descripcion dis_estado,
	distribuidor.rfc dis_rfc,

	case when cotizador.is_usado =1 then 
		case when cotizador.des_autou like '%SUBARU%' then 
			'SUBARU'
		else
			marca.descripcion
		end
	else
		marca.descripcion
	end as veh_marca,
	case when cotizador.is_usado =1 then cotizador.des_autou
		 else autos.des_auto 
		 end as veh_auto,
	case when cotizador.is_usado = 1  
			then cotizador.des_autou 
         else 
			ISNULL((select des_auto from cat_auto where id_auto = cotizador.id_auto),'') + ' ' +
			ISNULL((select descripcion from tipo where id_tipo = cotizador.id_tipo),'') + ' ' +
			ISNULL((select descripcion from modelo where id_modelo = cotizador.id_modelo),'')
         end as veh_automovil,
	tipo.descripcion veh_version,
	modelo.id_modelo veh_idmodelo,
	modelo.descripcion veh_modelo,
	ISNULL(tipo.cve_nasa,'') veh_cvenasa,
	tipo.cap veh_capacidad,
	case when ISNULL(cotizador.is_precioM,0) = 1 then cotizador.n_precio else CASE WHEN [DBO].[GETSUBSIDIOCOTIZACION] (cotizador.ID_COTIZACION,1,CAT_PLAZO.DES_PLAZO) > 0 THEN cotizador.PRECIO - [DBO].[GETSUBSIDIOCOTIZACION] (cotizador.ID_COTIZACION,1,CAT_PLAZO.DES_PLAZO) ELSE cotizador.n_precio END end AS veh_precio,
	case when cotizador.n_precio is null then 0 else n_precio end as veh_preciosindesc,
	case when ISNULL(cotizador.is_precioM,0) = 1 then cotizador.n_precio 
		 else case when cotizador.is_usado = 1 
         		then cotizador.n_precio 
         		else cotizador.precio 
			  end 
		end as veh_preciolista,
	cotizador.precio_pp veh_preciopp,
	case when promo.id_tipo_plan = 6 then convert(numeric(16,2),round(case when ISNULL(cotizador.is_precioM,0) = 1 then cotizador.n_precio else (CASE WHEN [DBO].[GETSUBSIDIOCOTIZACION] (cotizador.ID_COTIZACION,1,CAT_PLAZO.DES_PLAZO) > 0 THEN cotizador.PRECIO - [DBO].[GETSUBSIDIOCOTIZACION] (cotizador.ID_COTIZACION,1,CAT_PLAZO.DES_PLAZO) ELSE N_PRECIO END + cotizador.ACCE_FIN)/(1+(cotizador.IVA/100)) end,2))
         else convert(numeric(16,2),round(case when ISNULL(cotizador.is_precioM,0) = 1 then cotizador.n_precio else (CASE WHEN [DBO].[GETSUBSIDIOCOTIZACION] (cotizador.ID_COTIZACION,1,CAT_PLAZO.DES_PLAZO) > 0 THEN cotizador.PRECIO - [DBO].[GETSUBSIDIOCOTIZACION] (cotizador.ID_COTIZACION,1,CAT_PLAZO.DES_PLAZO) ELSE N_PRECIO END + cotizador.ACCE_FIN * (1+cotizador.IVA/100))/(1+(cotizador.IVA/100)) end,2)) 
	      end as veh_preciosiniva,
	case when(cotizador.n_precio - (case when [dbo].[getSubsidioCotizacion] (cotizador.id_cotizacion,1,cat_plazo.des_plazo) > 0 then cotizador.precio - [dbo].[getSubsidioCotizacion] (cotizador.id_cotizacion,1,cat_plazo.des_plazo) else n_precio end)) < 0 then 0 else (cotizador.n_precio-(case when [dbo].[getSubsidioCotizacion] (cotizador.id_cotizacion,1,cat_plazo.des_plazo) > 0 then cotizador.precio - [dbo].[getSubsidioCotizacion] (cotizador.id_cotizacion,1,cat_plazo.des_plazo) else n_precio end)) end as descuento,
	modelo.clave_unica veh_claveunica,
	modelo.id_producto veh_idproducto,
	cat_autos.descripcion veh_categoriaauto,
	cotizador.is_usado veh_isusado,
	cotizador.fec_alta fechageneracion,
	cat_persona.descripcion tipopersona,
	usuario.nombre+' '+ISNULL(usuario.paterno,'')+' '+ISNULL(usuario.materno,' ') quiencotizo,
	promo.descripcion promocion,
	promo.id_tipo_plan tipoplan,
	cat_promo.descripcion categoriapromo,
	cotizador.tasa,
	 convert(numeric(16,2),round(((pago * des_plazo * cotizador.id_periodicidad + n_balloon + 
	(case when anualidad = 1 then (select     count(cat_mensualidad.id_mensualidad) 
	from cat_mensualidad inner join bd_cotizacion on cat_mensualidad.id_mensualidad <= cat_plazo.des_plazo and month(dateadd(M, cat_mensualidad.id_mensualidad - 1, convert(datetime, cast(cotizador.mes_ini as varchar) + '-' + cast(cotizador.dia_ini as varchar) + '-' + cast(cotizador.ano_ini as varchar), 102))) = cotizador.mes_an AND month(dateadd(M, cat_mensualidad.id_mensualidad - 1, convert(datetime, cast(cotizador.mes_ini as varchar) + '-' + cast(cotizador.dia_ini as varchar) + '-' + cast(cotizador.ano_ini as varchar), 102))) = cotizador.mes_an
	where (cotizador.id_cotizacion = 7806192) AND (cat_mensualidad.id_mensualidad <> 1)) else 0 end + case when ultima = '1' then 1 else 0 end) * monto_anualidad) - (mon_fina + case when id_pago = 2 and id_seg_anual = 2 then [dbo].[MontoSeguroDiferido]( id_cotizacion,des_plazo) else 0 end )) / (1 + (cotizador.iva / 100)),2)) as totalintereses,
	--cotizador.totalintereses
	cotizador.enganche,
	cotizador.por_enganche,
	cotizador.renta,

	case when promo.id_tipo_plan = 6
			then 
         		isnull(cotizador.renta,0) * (1+cotizador.iva/100) * (isnull(cotizador.pago_ap,0)+isnull(cotizador.pago_seguro,0))
         	else
         		isnull(cotizador.renta,0) * isnull(cotizador.pago_ap,0)
         	end as depositogarantia,
	cotizador.mon_fina,
	cotizador.n_plazo plazo,
	isnull(cotizador.n_plazo,0) * isnull(cotizador.id_periodicidad,0) as desplazo,
	cotizador.des_ini desembolso,
	case when promo.id_tipo_plan = 2 OR promo.id_tipo_plan = 6 
          	    then cotizador.pago + ROUND(ROUND(cotizador.mon_fina * ((cotizador.tasa * 365) / (100.0 * 360.0 * 12.0 * cotizador.id_periodicidad)), 2) * cotizador.iva / 100, 2) + ROUND((PAGO - ROUND(cotizador.mon_fina * ((cotizador.tasa * 365.0) / (100.0 * 360.0 * 12.0 * cotizador.id_periodicidad)), 2)) * cotizador.iva / 100, 2)
           else 
          			case when 0 = 0 
           				then cotizador.pago
           			else 
           				0 
          			end 
           end as montoxmes,
	cotizador.pago,
	CAST(cotizador.pago / (1 +(cotizador.iva/100)) AS DECIMAL(13,2)) pagosinIva,
	cotizador.iva,
	isnull(cotizador.comision_monto,0) comision,
	isnull(cotizador.comision_monto,0) / (1 +(cotizador.iva/100)) comisionsiniva,
	cotizador.comision por_comision,
	cotizador.acce_fin accesoriosF,
	--cotizador.acce as accesoriosT,

	CASE WHEN cotizador.id_marca = 1 and SUBSTRING(promo.DESCRIPCION,1,2) ='AP'
	THEN 
		 cotizador.acce
	ELSE 
		cotizador.acce * (1+cotizador.IVA/100)
	END as accesoriosT,


	cotizador.id_periodicidad idPeriodicidad,
	CASE cotizador.id_periodicidad  
         WHEN 1 THEN 'MESES'  
         WHEN 2 THEN 'QUINCENAS' 
         ELSE ' '  
      END periodicidadPago,
	cotizador.dia_ini,
	cotizador.mes_ini,
	cotizador.ano_ini,
	CONVERT(VARCHAR(4), cotizador.ano_ini) + 
	   CASE WHEN cotizador.mes_ini < 10 THEN '0'
			ELSE ''
			END
	   +CONVERT(VARCHAR(2), cotizador.mes_ini) + 
	   CASE WHEN cotizador.dia_ini < 10 THEN '0'
			ELSE ''
			END
       +CONVERT(VARCHAR(2), cotizador.dia_ini) fechaprimerpago,

    convert (varchar,(DATEADD(d, - 15,DATEADD(m, - convert(int,cat_plazo.des_plazo),CONVERT(datetime,convert(varchar,cotizador.dia_fin) + '-' + convert(varchar,cotizador.mes_fin) + '-' + convert(varchar,cotizador.ano_fin), 103)))),105) fechaprimerpago15,
	--CAMBIARRRRRRRR
	convert (varchar,(dateadd (day,-45,convert(varchar,ano_ini)+'/'+convert(varchar,mes_ini)+'/'+convert(varchar,dia_ini))),105) fechaprimerpago15TXT,
	convert (varchar,(dateadd (day,-45,convert(varchar,ano_ini)+'/'+convert(varchar,mes_ini)+'/'+convert(varchar,dia_ini))),105) fechaprimerpago45,

	
	   CONVERT(VARCHAR(4), cotizador.ano_fin) + 
	   CASE WHEN cotizador.mes_fin < 10 THEN '0'
			ELSE ''
			END
	   +CONVERT(VARCHAR(2), cotizador.mes_fin) + 
	   CASE WHEN cotizador.dia_fin < 10 THEN '0'
			ELSE ''
			END
       +CONVERT(VARCHAR(2), cotizador.dia_fin) fechaultimopago,
	--CAMBIARRRRRRRR
	convert (varchar,(dateadd (day,-45,convert(varchar,ano_fin)+'/'+convert(varchar,mes_fin)+'/'+convert(varchar,dia_fin))),105) fechaultimopago15TXT,
	
	cotizador.n_balloon balloon,
	convert(numeric(16,2),round(((cotizador.n_balloon*100)/cotizador.n_precio),2)) por_balloon,
	DATEDIFF(d, DATEADD(d, - 15, DATEADD(m, - CONVERT(INT,CAT_PLAZO.DES_PLAZO), CONVERT(datetime, cotizador.DIA_FIN + '-' + cotizador.MES_FIN + '-' + cotizador.ANO_FIN, 103))), CONVERT(datetime, cotizador.DIA_FIN + '-' + cotizador.MES_FIN + '-' + cotizador.ANO_FIN, 103)) AS duracion,
	CONVERT(varchar(20), CONVERT(money, ((CASE WHEN [DBO].[GETSUBSIDIOCOTIZACION] (cotizador.ID_COTIZACION,1,CAT_PLAZO.DES_PLAZO) > 0 THEN cotizador.PRECIO - [DBO].[GETSUBSIDIOCOTIZACION] (cotizador.ID_COTIZACION,1,CAT_PLAZO.DES_PLAZO) ELSE N_PRECIO END + cotizador.ACCE_FIN)-cotizador.ENGANCHE)/cotizador.MON_FINA*cotizador.N_BALLOON),1) AS amortfin,

	ISNULL(cotizador.anualidad,0) anualidad,
	cotizador.monto_anualidad montoanualidad,
	cotizador.mes_an mesanualidad,
	--ISNULL(cotizador.ultima,0) ultimaanualidad,
	cotizador.ultima ultimaanualidad,
	--disclaimerA
	case when promo.id_tipo_plan = 6
			then 
'Cada uno de los rubros y montos expresados en esta cotización, son estrictamente referenciales y corresponden a un ejercicio numérico del producto denominado Arrendamiento Puro otorgado por TOYOTA FINANCIAL SERVICES MÉXICO, S.A. de C.V., en razón de ello, dichos elementos pueden variar al momento de su contratación, razón por la cual le sugerimos verificarlos de forma exhaustiva antes de firmar el contrato respectivo. El importe expresado en el rubro: Estimación de Valor de Mercado (EVM) no constituye un precio definitivo ni una oferta de venta para el Arrendatario y deberá ser interpretado exclusivamente como elemento meramente referencial, ya que en caso de manifestar interés en comprar el vehículo materia del arrendamiento, el precio de venta será calculado tomando como base los valores entonces vigentes en el mercado para el vehículo materia de arrendamiento, así como por las condiciones físicas, mecánicas, fiscales y ambientales del mismo al finalizar el plazo del arrendamiento.
La presente cotización podrá variar en la medida en que las condiciones de mercado varíen, por ello le recomendamos verificar las mismas al momento de realizar la contratación con el distribuidor Toyota de su preferencia. Asimismo, le informamos que la emisión e impresión de este documento no representa una autorización de crédito.'
         	else
'Cotización en pesos mexicanos, sujeta a cambio sin previo aviso, debido al comportamiento del mercado o tipo de cambio. Precio del vehículo incluye ISAN. El seguro es contratado por Toyota Financial Services México y pagado por el cliente. Seguro contratado con '+ cat_aseguradora.descripcion + ' . vigente por el plazo total del financiamiento. 				
El cliente es responsable de los pagos de tenencia del vehículo, del mantenimiento y conservación adecuada del vehículo y de los costos en los que incurra al respecto. Sujeto a autorización del crédito. 
En operaciones de financiamiento con pagos extraordinarios, el seguro de desempleo solo cubrirá el monto correspondiente a una mensualidad normal sin el pago extraordinario.En financiamientos o arrendamientos mayores a 36 meses, aplica cobertura de tercer año valor factura.
Los intereses que el CLIENTE deba pagar a TFSM, se calcularán sobre la base de un año de 360 días dividido en doce periodos mensuales iguales de 30.4167 días, resultado de dividir 365 días entre 12 meses. '+cast(cotizador.cat as varchar)+'% sin IVA, fijo. Costo Anual Total para fines informativos y de comparación exclusivamente.
El cliente podrá contratar los seguros de manera independiente los cuales deberán cumplir con las condiciones establecidas por TFSMx las cuales podrán consultar en www.toyotacredito.com.mx'
         	end as disclaimerA,
	--disclaimerB
'Al término de crédito, usted tiene las siguientes opciones para liquidar el valor residual (Balloon):
1. Liquidar a TFSM en una sola exhibición el monto total del valor residual (Balloon)
2. Solicitar a TFSM el refinanciamiento del valor residual por un plazo de hasta 18 meses, previa autorización de TFSM.
3. Acudir al distribuidor, quien valuará el vehículo actual y podrá considerarlo para recibirlo como enganche para la adquisición de un nuevo vehículo Toyota' disclaimerB,
	cotizador.cat,
	--montoNeteo
	case when promo.id_tipo_plan = 6 THEN
		(CASE WHEN cotizador.id_marca = 1 and SUBSTRING(promo.DESCRIPCION,1,2) ='AP' 
		 THEN  
		 convert(varchar(20), convert(money, (case when ISNULL(cotizador.is_precioM,0) = 1 then cotizador.n_precio else case when [dbo].[getsubsidiocotizacion] (cotizador.id_cotizacion,1,cat_plazo.des_plazo) > 0 then cotizador.precio - [dbo].[getsubsidiocotizacion] (cotizador.id_cotizacion,1,cat_plazo.des_plazo) else n_precio end end) + (cotizador.acce_fin * (1+cotizador.IVA/100)) + cotizador.garantia - (cotizador.enganche + cotizador.des_ini - ((cotizador.ACCE ) - (cotizador.ACCE_FIN * (1+cotizador.IVA/100))))),1) 
		 ELSE  
		 convert(varchar(20), convert(money, (case when ISNULL(cotizador.is_precioM,0) = 1 then cotizador.n_precio else case when [dbo].[getsubsidiocotizacion] (cotizador.id_cotizacion,1,cat_plazo.des_plazo) > 0 then cotizador.precio - [dbo].[getsubsidiocotizacion] (cotizador.id_cotizacion,1,cat_plazo.des_plazo) else n_precio end end) + (cotizador.acce_fin * (1+cotizador.IVA/100)) + cotizador.garantia - (cotizador.enganche + cotizador.des_ini - ((cotizador.ACCE * (1+cotizador.IVA/100)) - (cotizador.ACCE_FIN * (1+cotizador.IVA/100))))),1) 
		 END)

	else
		(case	when ISNULL(cotizador.is_precioM,0) = 1 
				then cotizador.n_precio 
			else case	when [dbo].[getsubsidiocotizacion] (cotizador.id_cotizacion,1,cat_plazo.des_plazo) > 0 
							then cotizador.precio - [dbo].[getsubsidiocotizacion] (cotizador.id_cotizacion,1,cat_plazo.des_plazo) 
						else n_precio 
						end 
			end)-(cotizador.enganche+cotizador.comision_monto + 
			
					case	when cotizador.id_pago=2 
							then 0 
							else  dbo.getTotalSeguros(cotizador.id_cotizacion) 
							end) + 
		cotizador.acce_fin 
	end as montoneteo,

	cotizador.ratificacion as ratificacioncontrato,
	cotizador.residual as valorresidual,
	(cotizador.residual*n_precio)/100 as montoresidual,
	cotizador.opcion_comp as opcioncompra,
	--totalPago
	0.00 totalpago,
	--descripcionPaqueteSubsidio
	isnull((select descripcion from config_subsidios where id_config = (select distinct top(1) id_config from cotizacion_subsidios_detalle where id_cotizacion = cotizador.id_cotizacion)),'Subsidio') AS descripcionpaquete,
	
	--subsidiomontoDealer
	[dbo].[getSubsidioCotizacionActorSubsidio] (cotizador.id_cotizacion,cat_plazo.des_plazo,1,2) + [dbo].[getSubsidioCotizacionActorSubsidio] (cotizador.id_cotizacion,cat_plazo.des_plazo,1,4) as montodealer,
	--subsidiomontoTMEX
	[dbo].[getSubsidioCotizacionActorSubsidio] (cotizador.id_cotizacion,cat_plazo.des_plazo,2,2) + [dbo].[getSubsidioCotizacionActorSubsidio] (cotizador.id_cotizacion,cat_plazo.des_plazo,2,4) as montoTMEX,

	cat_aseguradora.descripcion aseguradora,
	cat_aseguradora.aseg_danos asegdanos,
	--polizaCode
	CONVERT(varchar(20),ISNULL(cat_aseguradora.id_aseguradora,'')) polizacode,
	
	cotizador.num_poliza numeropoliza,
	--prefijoPoliza
	ISNULL(CASE WHEN cotizador.id_aseguradora = 1 THEN (SELECT TOP 1 PREFIJO FROM ASEGURADORA_RANGOS WHERE ASEGURADORA_RANGOS.ID_ASEGURADORA = cotizador.ID_ASEGURADORA AND ASEGURADORA_RANGOS.ID_STATUS = 1 AND ASEGURADORA_RANGOS.IVA = cotizador.IVA AND PREFIJO!='') ELSE (SELECT TOP 1 PREFIJO FROM ASEGURADORA_RANGOS WHERE ASEGURADORA_RANGOS.ID_ASEGURADORA = cotizador.ID_ASEGURADORA AND ASEGURADORA_RANGOS.ID_STATUS = 1 AND PREFIJO!='') END , '') AS prefijopoliza,
	cotizador.fec_generada fechageneracionpoliza,
	cotizador.seg_danos segurodanos,
	convert(numeric(16,2),round(((cotizador.seg_danos * cotizador.iva) / (100+cotizador.iva)),2)) montoivasegdanos,
	convert(numeric(16,2),round(cotizador.seg_danos/n_plazo_seg ,2)) costopormes,
	convert(numeric(16,2),round(cotizador.seg_danos/(n_plazo_seg/12),2)) costoproanual,
	cotizador.id_seg_anual seguroAnual,
	cotizador.seg_danos_gap - cotizador.seg_danos montogap,
	CAST(((cotizador.seg_danos_gap - cotizador.seg_danos) / (1 +(cotizador.iva/100))) AS DECIMAL(13,2)) montosinivagap,
	CAST(((cotizador.seg_danos_gap - cotizador.seg_danos) * (cotizador.iva/(100+cotizador.iva))) AS DECIMAL(13,2)) ivagap,
	cotizador.seg_vida segurovida,
	cotizador.id_garantia tipootrosfin,
	cat_protext.descripcion protext_descripcion,
	cotizador.garantia protext_monto,
	cotizador.rc_extranjera rcext,
	CASE WHEN cotizador.ID_PAGO=2 THEN 0 ELSE  dbo.getTotalSeguros(cotizador.id_cotizacion) END as totsegurosfina,
	isnull(cotizador.seg_vida,0) + isnull(cotizador.seg_danos_gap,0) + isnull(cotizador.rc_extranjera,0) as totseguros,
	n_cobertura idcobertura,
	cat_cobertura.descripcion cobertura,
	REPLACE(cat_cobertura.leyenda,CHAR(10), '<br>') leyenda,
	cat_cobertura.id_prolease idcoberturaprolease,
	factores.caratula,
	isnull(cotizador.pago_seguro,0) as pagoseguro,
	--derecho
	aseguradora_catauto.derecho,
	cotizador.id_uso,
	cat_uso.des_uso uso,
	case when cotizador.id_pago = 2 and cotizador.id_seg_anual = 2 
			then 'DIFERIDO' 
		 else (select descripcion from cat_pago where id_pago = cotizador.id_pago)
         end as tipopago,
	--anual
	0.00 anual,
	cat_estados.descripcion edocirculacion,
	--gastosexpedicion
	2000.00 gastosexpedicion,
	--primasegdanosneta
	(cotizador.seg_danos/(1+(cotizador.iva/100)))-aseguradora_catauto.derecho primasegdanosneta,

	case when cotizador.id_estado = (select id_estado from cat_dealer where cat_dealer.id_dealer = cotizador.id_dealer) 
         	then 'NO' 
         	else 'SI' + ',' + (select descripcion from cat_estados where cat_estados.id_estado = cotizador.id_estado) 
         	end as seguroabierto,

	CASE WHEN (
		SELECT COUNT(*)  FROM [APS_Notificaciones] A inner JOIN [APS_ColAccesorios]  B 
	     ON A.[IdColAccesorios] = B.[IdColAccesorios] 
	     INNER JOIN [APS_CatAccesorios] C ON B.[IdAccesorio] = C.[IdAccesorio] 
		 WHERE  [ID_COTIZACION] = cotizador.id_cotizacion AND B.IdAccesorio in(6,9))>0 THEN 
			CASE WHEN (SELECT COUNT(*)  FROM [APS_Notificaciones] A inner JOIN [APS_ColAccesorios]  B 
				 ON A.[IdColAccesorios] = B.[IdColAccesorios] 
				 INNER JOIN [APS_CatAccesorios] C ON B.[IdAccesorio] = C.[IdAccesorio] 
				 WHERE  [ID_COTIZACION] = cotizador.id_cotizacion AND B.IdAccesorio in(6))>0 THEN 'STD'
			ELSE 'AUT'
			END
	ELSE '' 
	END AS trans,

	CASE WHEN (
		SELECT COUNT(*)  FROM [APS_Notificaciones] A inner JOIN [APS_ColAccesorios]  B 
	     ON A.[IdColAccesorios] = B.[IdColAccesorios] 
	     INNER JOIN [APS_CatAccesorios] C ON B.[IdAccesorio] = C.[IdAccesorio] 
		 WHERE  [ID_COTIZACION] = cotizador.id_cotizacion AND B.IdAccesorio=5)>0 THEN 'C A/AC'
	ELSE '' 
	END AS aire,
	0.00 subsidioTP,
	convert(numeric(16,2),round((([dbo].[getSubsidioCotizacionActorSubsidio] (cotizador.id_cotizacion,cat_plazo.des_plazo,1,2) + [dbo].[getSubsidioCotizacionActorSubsidio] (cotizador.id_cotizacion,cat_plazo.des_plazo,1,4))* (1 + (cotizador.iva/100))),2)) subsidiotasa,
	case when cotizador.id_periodicidad = 2 then 1
		 when promo.id_categoria = 2 then 1
		 else 0
		 end as isEmpleado,
	(select convert(decimal(18,2),valor) as valor from cat_parametros where id_conf = 1 and id_status = 1) as tasaexempleado,
	2500 * (1+(cotizador.iva/100)) comisionprepago,
	0.00 comisionporgestion,
	promo.cobranza * (1+(cotizador.iva/100)) cobranzalegal, 
	promo.mora,
	case when promo.id_tipo_plan = 6 then (case when cotizador.id_marca != 2 then 25000 else 56000 end)--puro ,
	     when promo.id_tipo_plan = 2 then (case when cotizador.id_marca != 2 then 25000 else 75000 end)
	     else 0 
	     end as kilometrajeanual,
	cotizador.n_precio * (prom_plazo.evm/100) as evm,
	CASE WHEN ISNULL((SELECT STATUS FROM [BD_COT4].[dbo].[cotizacion_permisos] WHERE id_permiso=6 and id_cotizacion=7806192),0) = 1 THEN 'SI'
            ELSE 'NO'
			END AS estadoabierto,
	modelo.id_producto idproducto

  FROM [BD_COT4].[dbo].[bd_cotizacion] cotizador
  INNER JOIN [BD_COT4].dbo.cat_dealer distribuidor
	ON cotizador.id_dealer = distribuidor.id_dealer
  INNER JOIN [BD_COT4].dbo.cat_estados estado
	ON distribuidor.id_estado = estado.id_estado
  INNER JOIN [BD_COT4].dbo.cat_marcas marca
	ON cotizador.id_marca = marca.id_marca
  INNER JOIN [BD_COT4].dbo.cat_auto autos
	ON cotizador.id_auto = autos.id_auto
  INNER JOIN [BD_COT4].dbo.tipo tipo
	ON cotizador.id_tipo = tipo.id_tipo
  INNER JOIN [BD_COT4].dbo.modelo modelo
	ON cotizador.id_modelo = modelo.id_modelo
  INNER JOIN [BD_COT4].dbo.cat_categoria_auto cat_autos
	ON autos.id_categoria_auto = cat_autos.id_categoria_auto
  INNER JOIN [BD_COT4].[dbo].cat_persona cat_persona
	ON cotizador.id_persona = cat_persona.id_persona
  INNER JOIN [BD_COT4].[dbo].usuarios usuario
	ON cotizador.reg_alta = usuario.id_usuario
  LEFT JOIN [BD_COT4].[dbo].cat_estados cat_estados
	ON cat_estados.id_estado = cotizador.id_estado
  LEFT JOIN [BD_COT4].dbo.cat_promociones promo
	ON cotizador.id_promocion = promo.id_promocion
  LEFT JOIN [BD_COT4].dbo.cat_categoria_promocion cat_promo
	ON promo.id_categoria = cat_promo.id_categoria
  LEFT JOIN [BD_COT4].dbo.cat_aseguradora cat_aseguradora
	ON cat_aseguradora.id_aseguradora = cotizador.id_aseguradora
  LEFT JOIN [BD_COT4].dbo.aseguradora_catauto 
	ON (cotizador.id_aseguradora = aseguradora_catauto.id_aseguradora
		AND autos.id_categoria_auto = aseguradora_catauto.id_categoria_auto AND aseguradora_catauto.id_status = 1)
  LEFT JOIN [BD_COT4].dbo.cat_garantia cat_protext
	ON cat_protext.id_garantia = cotizador.id_garantia
  LEFT JOIN [BD_COT4].dbo.cat_cobertura cat_cobertura
	ON cat_cobertura.id_cobertura = cotizador.n_cobertura
  LEFT JOIN [BD_COT4].dbo.FACTORES 
	ON cotizador.ID_MODELO = FACTORES.ID_MODELO AND cotizador.N_COBERTURA = FACTORES.ID_COBERTURA
  LEFT JOIN [BD_COT4].dbo.cat_uso cat_uso
	ON cat_uso.id_uso = cotizador.id_uso
  LEFT JOIN prom_plazo 
	ON (prom_plazo.id_promocion = cotizador.id_promocion AND prom_plazo.id_plazo = cotizador.n_plazo)
  LEFT OUTER JOIN [BD_COT4].dbo.cat_plazo 
    ON cotizador.n_plazo = cat_plazo.id_plazo
  WHERE id_cotizacion = @idCotizacion
  order by id_cotizacion desc;


END



/*

SELECT 
CASE WHEN (
SELECT COUNT(*)  FROM [APS_Notificaciones] A inner JOIN [APS_ColAccesorios]  B 
	     ON A.[IdColAccesorios] = B.[IdColAccesorios] 
	     INNER JOIN [APS_CatAccesorios] C ON B.[IdAccesorio] = C.[IdAccesorio] 
		 WHERE  [ID_COTIZACION] = 7798991 AND B.IdAccesorio in(6,9))>0 THEN 
			CASE WHEN (SELECT COUNT(*)  FROM [APS_Notificaciones] A inner JOIN [APS_ColAccesorios]  B 
				 ON A.[IdColAccesorios] = B.[IdColAccesorios] 
				 INNER JOIN [APS_CatAccesorios] C ON B.[IdAccesorio] = C.[IdAccesorio] 
				 WHERE  [ID_COTIZACION] = 7798991 AND B.IdAccesorio in(6))>0 THEN 'STD'
			ELSE 'AUT'
			END
	ELSE '' 
	END AS trans,

CASE WHEN (
	SELECT COUNT(*)  FROM [APS_Notificaciones] A inner JOIN [APS_ColAccesorios]  B 
	     ON A.[IdColAccesorios] = B.[IdColAccesorios] 
	     INNER JOIN [APS_CatAccesorios] C ON B.[IdAccesorio] = C.[IdAccesorio] 
		 WHERE  [ID_COTIZACION] = 7798991 AND B.IdAccesorio=5)>0 THEN 'C A/AC'
			
	ELSE '' 
	END AS aire


SELECT A.[IdColAccesorios] 
         ,B.[IdAccesorio]  
         ,[Descripcion] 
		 ,convert(numeric,[Activo]) ACTIVO 
  		 FROM [APS_Notificaciones] A inner JOIN [APS_ColAccesorios]  B 
	     ON A.[IdColAccesorios] = B.[IdColAccesorios] 
	     INNER JOIN [APS_CatAccesorios] C ON B.[IdAccesorio] = C.[IdAccesorio] 
		 WHERE  [ID_COTIZACION] = 7798991

		 SELECT TOP 100 * FROM [APS_Notificaciones]
		 ORDER BY ID_COTIZACION DESC

		 SELECT TOP 100 * FROM APS_ColAccesorios

		 SELECT TOP 100 * FROM [APS_CatAccesorios] 

--totalinteres

select 
 convert(numeric(16,2),round(((pago * des_plazo * id_periodicidad + n_balloon + 
	(case when anualidad = 1 then (select     count(cat_mensualidad.id_mensualidad) 
	from cat_mensualidad inner join bd_cotizacion on cat_mensualidad.id_mensualidad <= cat_plazo.des_plazo and month(dateadd(M, cat_mensualidad.id_mensualidad - 1, convert(datetime, cast(cotizador.mes_ini as varchar) + '-' + cast(cotizador.dia_ini as varchar) + '-' + cast(cotizador.ano_ini as varchar), 102))) = cotizador.mes_an AND month(dateadd(M, cat_mensualidad.id_mensualidad - 1, convert(datetime, cast(cotizador.mes_ini as varchar) + '-' + cast(cotizador.dia_ini as varchar) + '-' + cast(cotizador.ano_ini as varchar), 102))) = cotizador.mes_an
	where (cotizador.id_cotizacion = 7806192) AND (cat_mensualidad.id_mensualidad <> 1)) else 0 end + case when ultima = '1' then 1 else 0 end) * monto_anualidad) - (mon_fina + case when id_pago = 2 and id_seg_anual = 2 then [dbo].[MontoSeguroDiferido]( id_cotizacion,des_plazo) else 0 end )) / (1 + (iva / 100)),2)) as int_tot
	from bd_cotizacion cotizador
	inner join cat_plazo on cotizador.n_plazo = cat_plazo.id_plazo
	where id_cotizacion = 7806192

72379.28

select convert(decimal(18,2),valor) as valor from cat_parametros where id_conf = 1 and id_status = 1

select day(dateadd (day,-45,convert(varchar,dia_ini)+'/'+convert(varchar,mes_ini)+'/'+convert(varchar,ano_ini))
,dia_ini,mes_ini,ano_ini
 from bd_cotizacion cotizador
where id_cotizacion = 7806192



SELECT top 100 *
from bd_cotizacion cotizador
LEFT JOIN [BD_COT4].dbo.cat_promociones promo
	ON cotizador.id_promocion = promo.id_promocion
where promo.id_tipo_plan=1 and cotizador.garantia>0
order by id_cotizacion desc


SELECT REPLACE(CAT_COBERTURA.LEYENDA,CHAR(10), '<br>') AS LEYENDA, 
                 BD_COTIZACION.ID_COTIZACION 
                 FROM BD_COTIZACION 
                 INNER JOIN CAT_COBERTURA ON BD_COTIZACION.N_COBERTURA = CAT_COBERTURA.ID_COBERTURA 
                 WHERE (((BD_COTIZACION.ID_COTIZACION)=7806192))




select CONVERT(VARCHAR(4), cotizador.ano_ini) + '-' +
	   CASE WHEN cotizador.mes_ini < 10 THEN '0'
			ELSE ''
			END
	   +CONVERT(VARCHAR(2), cotizador.mes_ini) + '-' +
	   CASE WHEN cotizador.dia_ini < 10 THEN '0'
			ELSE ''
			END
       +CONVERT(VARCHAR(2), cotizador.dia_ini) fechaprimerpago,

	   CONVERT(VARCHAR(4), cotizador.ano_fin) + '-' +
	   CASE WHEN cotizador.mes_fin < 10 THEN '0'
			ELSE ''
			END
	   +CONVERT(VARCHAR(2), cotizador.mes_fin) + '-' +
	   CASE WHEN cotizador.dia_fin < 10 THEN '0'
			ELSE ''
			END
       +CONVERT(VARCHAR(2), cotizador.dia_fin) fechaultimopago

	   --CONVERT(VARCHAR(2), cotizador.dia_ini)+ '/' --+ ''+cotizador.mes_ini+ '/' + ''+cotizador.ano_ini as fechaprimerpago
	--CHAR(cotizador.dia_fin) + '/' + CHAR(cotizador.mes_fin) + '/' + CHAR(cotizador.ano_fin) as fechaultimopago
	FROM [BD_COT4].[dbo].[bd_cotizacion] cotizador
	where id_cotizacion = 6078061

	select cast(round(324396.5597241379310344,2) as DECIMAL(9,6))

	select convert(numeric(16,2),round(324396.5517241379310344,2)) 


	


	select * from [BD_COT4].[dbo].cat_plazo

	select top 100 subsidio
	from [BD_COT4].[dbo].[bd_cotizacion]

	where id_cotizacion = 7806302
	--n_cobertura is null
	order by id_cotizacion desc

		select top 100 id_cotizacion,seg_danos_gap-seg_danos
	from [BD_COT4].[dbo].[bd_cotizacion]

SELECT TOP 1000 cotizador.id_cotizacion,orden.des_amparadas,orden.sum_aseg,orden.deducible,orden.primas 
  FROM [BD_COT4].[dbo].[bd_cotizacion] cotizador
  LEFT JOIN [BD_COT4].dbo.amparadas orden
  ON (cotizador.n_cobertura = orden.id_cobertura AND cotizador.id_uso = orden.id_uso)
  WHERE id_cotizacion = 7806292
  order by id_cotizacion desc


  SELECT * FROM [BD_COT4].dbo.amparadas
  where id_cobertura=15
  and id_uso=1

  


SELECT 
 AMPARADAS.DES_AMPARADAS, 
 CONVERT(varchar(20), CONVERT(money, AMPARADAS.SUM_ASEG),1) AS SUM_ASEG, 
 CASE WHEN AMPARADAS.AMPARADA ='AMPARADA_AC' 
 	THEN  CASE WHEN BD_COTIZACION.ACCE = 0 
 		THEN 'EXCLUIDA' 
 		ELSE '$' + ' ' + CONVERT(varchar(20), CONVERT(money, BD_COTIZACION.ACCE),1) 
 		END 
 	ELSE CASE  WHEN AMPARADAS.AMPARADA ='EXCLUIDA' 
 		THEN 'EXCLUIDA' 
 		ELSE  CASE  WHEN AMPARADAS.AMPARADA ='AMPARADA_VA' 
 			THEN '$' + ' ' + CONVERT(varchar(20), CONVERT(money, CASE WHEN ISNULL(BD_COTIZACION.IS_PRECIOM,0) = 1 THEN N_PRECIO ELSE CASE WHEN [DBO].[GETSUBSIDIOCOTIZACION] (BD_COTIZACION.ID_COTIZACION,1,CAT_PLAZO.DES_PLAZO) > 0 THEN BD_COTIZACION.PRECIO - [DBO].[GETSUBSIDIOCOTIZACION] (BD_COTIZACION.ID_COTIZACION,1,CAT_PLAZO.DES_PLAZO) ELSE N_PRECIO END END),1) 
 			ELSE CASE WHEN AMPARADAS.AMPARADA ='AMPARADAB' 
 				THEN CASE WHEN AMPARADAS.SUM_ASEG > 100 OR AMPARADAS.SUM_ASEG < 0 
 					THEN 'ERROR %' 
 					ELSE '$' + ' ' + CONVERT(varchar(20),CONVERT(money,(CASE WHEN ISNULL(BD_COTIZACION.IS_PRECIOM,0) = 1 
 						THEN N_PRECIO 
 						ELSE CASE WHEN [dbo].[getSubsidioCotizacion] (BD_COTIZACION.ID_COTIZACION,1,CAT_PLAZO.des_plazo) > 0 
 							THEN BD_COTIZACION.PRECIO - [dbo].[getSubsidioCotizacion] (BD_COTIZACION.ID_COTIZACION,1,CAT_PLAZO.des_plazo) 
 							ELSE N_PRECIO 
 							END 
 						END	* ((CONVERT(numeric(14,4),AMPARADAS.SUM_ASEG)/100)))),1) 
 					END	
 				ELSE CASE  WHEN AMPARADAS.SUM_ASEG > 0 
 					THEN '$' + ' ' + CONVERT(varchar(20), CONVERT(money, AMPARADAS.SUM_ASEG),1) 
 					ELSE 'AMPARADA' 
 					END 
 				END 
 			END 
 		END 
 	END AS SUM_ASEG1, 
 AMPARADAS.DEDUCIBLE, 
 AMPARADAS.PRIMAS
 FROM BD_COTIZACION 
 INNER JOIN AMPARADAS ON BD_COTIZACION.N_COBERTURA = AMPARADAS.ID_COBERTURA 
 INNER JOIN CAT_PLAZO ON BD_COTIZACION.N_PLAZO = CAT_PLAZO.ID_PLAZO 
 WHERE (BD_COTIZACION.ID_COTIZACION =7806192) AND (AMPARADAS.ID_STATUS = 1) AND (BD_COTIZACION.ID_USO = AMPARADAS.ID_USO)
 ORDER BY AMPARADAS.cve

 select top 100 NUM_POLIZA,NUM_CLI
 ,ISNULL(CASE WHEN cotizador.id_aseguradora = 1 THEN (SELECT PREFIJO FROM ASEGURADORA_RANGOS WHERE ASEGURADORA_RANGOS.ID_ASEGURADORA = cotizador.ID_ASEGURADORA AND ASEGURADORA_RANGOS.ID_STATUS = 1 AND ASEGURADORA_RANGOS.IVA = cotizador.IVA) ELSE (SELECT PREFIJO FROM ASEGURADORA_RANGOS WHERE ASEGURADORA_RANGOS.ID_ASEGURADORA = cotizador.ID_ASEGURADORA AND ASEGURADORA_RANGOS.ID_STATUS = 1) END , '') AS prefijopoliza
 from [BD_COT4].[dbo].[bd_cotizacion] cotizador
 WHERE NUM_POLIZA IS NOT NULL AND ID_ASEGURADORA=1 and len(num_poliza)=5
 and num_poliza!=0
 order by id_cotizacion desc

 select top 100 * from [BD_COT4].[dbo].[bd_cotizacion] cotizador
 WHERE id_aseguradora is not null and id_aseguradora!=0


 LEFT JOIN [BD_COT4].dbo.cat_promociones promo
	ON cotizador.id_promocion = promo.id_promocion
WHERE is_usado=1
order by id_cotizacion desc

select * from dbo.cat_dealer

select * from [BD_COT4].dbo.tipo tipo


	ON cotizador.id_tipo = tipo.id_tipo


 */