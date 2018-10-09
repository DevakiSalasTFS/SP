USE [BD_Cot4]
GO
/****** Object:  StoredProcedure [dbo].[spGetInfoCotizacion]    Script Date: 10/09/2018 11:02:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


create proc [dbo].[spGetInfoCotizacion] (@pidcotizacion int
, @piddealer int 
)  as
BEGIN
SET NOCOUNT ON;	

DECLARE @idPromocion int 
DECLARE @tieneVigencia int 
DECLARE @coincideDealer int

DECLARE @xmlEmpty XML = (
 N'<cotizacion>
	<informacionFinanciera>
		<numCotizacion></numCotizacion>
		<fechageneracion></fechageneracion>
		<tipoPersona></tipoPersona>
		<quiencotizo></quiencotizo>
		<auto></auto>
		<version></version>
		<modelo></modelo>
		<precio></precio>
		<promocion></promocion>
		<idtipoplan></idtipoplan>
		<tipoplan></tipoplan>
		<categoriapromocion></categoriapromocion>
		<tasa></tasa>
		<enganche></enganche>
		<depositoGarantia></depositoGarantia>
		<numrentasdeposito></numrentasdeposito>
		<montoafinanciar></montoafinanciar>
		<plazo></plazo>
		<desembolsoinicial></desembolsoinicial>
		<pago></pago>
		<pagosinIva></pagosinIva>
		<iva></iva>
		<comision></comision>
		<por_comision></por_comision>
		<comisionsiniva></comisionsiniva>
		<accesoriosFinanciados></accesoriosFinanciados>
		<accesoriosContado></accesoriosContado>
		<accesoriosTotales></accesoriosTotales>
		<periodicidadPago></periodicidadPago>
		<fechaprimerpago></fechaprimerpago>
		<fechaultimopago></fechaultimopago>
		<balloon></balloon>
		<montoAnualidad></montoAnualidad>
		<mesAnualidad></mesAnualidad>
		<ultima></ultima>
		<cat></cat>
		<ratificacioncontrato></ratificacioncontrato>
		<valorresidual></valorresidual>
		<opcioncompra></opcioncompra>
		<totalpago></totalpago>
		<evm></evm>
		<descripcionPaqueteSubsidio></descripcionPaqueteSubsidio>
		<subsidiomontoDealer></subsidiomontoDealer>
		<subsidiomontoTMEX></subsidiomontoTMEX>
		<aseguradora></aseguradora>
		<segurodedanos></segurodedanos>
		<montoivasegdanos></montoivasegdanos>
		<montoVF></montoVF >
		<montosVFiniva></montosVFiniva >
		<ivamontoVF></ivamontoVF >
		<segurodevida></segurodevida>
		<descripcionPE></descripcionPE >
		<montoPE></montoPE>
		<rcext></rcext>
		<totseguros></totseguros>
		<cobertura></cobertura>
		<uso></uso>
		<tipopago></tipopago>
		<anual></anual>
		<edocirculacion></edocirculacion>
		<fechaLimiteCompra></fechaLimiteCompra>
		<esUsado></esUsado>
		<marca></marca>
	</informacionFinanciera>
</cotizacion>
'
);

SET @idPromocion = (SELECT id_promocion FROM bd_cotizacion WHERE id_cotizacion = @pidcotizacion)
SET @tieneVigencia = (SELECT id_prom_vigencia FROM prom_vigencia WHERE id_promocion = @idPromocion and id_status = 1)
--(SELECT id_dealer FROM cat_dealer WHERE bid = CONVERT(VARCHAR,@piddealer) and id_status = 1)
--SELECT bid FROM cat_dealer WHERE id_dealer = (SELECT id_dealer FROM bd_cotizacion WHERE id_cotizacion = @pidcotizacion)
SET @coincideDealer = CASE WHEN (SELECT bid FROM cat_dealer WHERE id_dealer = (SELECT id_dealer FROM bd_cotizacion WHERE id_cotizacion = @pidcotizacion)) = @piddealer THEN 1
					  ELSE 0
					  END

--SELECT @tieneVigencia as TieneVigenciaActiva

IF @coincideDealer = 1 
BEGIN

DECLARE @xml XML = (
select 
	a.id_cotizacion as numCotizacion,a.fec_alta as fechageneracion, b.descripcion as tipoPersona,
	c.nombre+' '+ISNULL(c.paterno,'')+' '+ISNULL(c.materno,' ') as quiencotizo, 
	UPPER(n.des_auto) as auto,
	p.descripcion as version,
	o.descripcion as modelo,
	a.n_precio as precio,
	d.descripcion as promocion, 
	e.id_tipo_plan as idtipoplan,
	e.descripcion as tipoplan,
	f.descripcion as categoriapromocion, a.n_tasa as tasa, a.enganche , 
	case when d.id_tipo_plan = 6
			then 
         		isnull(a.renta,0) * (1+a.iva/100) * (isnull(a.pago_ap,0)+isnull(a.pago_seguro,0))
         	else
         		isnull(a.renta,0) * isnull(a.pago_ap,0)
         	end as depositoGarantia,
	a.renta as numrentasdeposito,
	--a.garantia as depositoGarantia,
	a.mon_fina as montoafinanciar, a.n_plazo as plazo, a.des_ini as desembolsoinicial, 
	case 
		when d.id_tipo_plan != 6  and d.id_tipo_plan != 2 then a.pago
		else  a.pago * (1 +(a.iva/100)) 
	end as pago ,
	case 
		when d.id_tipo_plan != 6  and d.id_tipo_plan != 2 then a.pago / (1 +(a.iva/100))
		else  a.pago
	end as pagosinIva,
	--a.pago,a.pago / (1 +(a.iva/100)) as pagosinIva,
	a.iva, a.comision_monto as comision, 
	--a.comision as por_comision,
	a.comision_monto / (1 +(a.iva/100)) as comisionsiniva,
	a.acce_fin as accesoriosFinanciados, a.acce - a.acce_fin as accesoriosContado, a.acce as accesoriosTotales, a.id_periodicidad as periodicidadPago,
	CONVERT(datetime, CONVERT(VARCHAR(2), a.dia_ini) + '-' + CONVERT(VARCHAR(2), a.mes_ini) + '-' + CONVERT(VARCHAR(4), a.ano_ini), 103) as fechaprimerpago, 
	CONVERT(datetime, CONVERT(VARCHAR(2), a.dia_fin) + '-' + CONVERT(VARCHAR(2), a.mes_fin) + '-' + CONVERT(VARCHAR(4), a.ano_fin) , 103) as fechaultimopago,
	a.n_balloon as balloon, a.monto_anualidad as montoAnualidad, a.mes_an as mesAnualidad, a.ultima,
	a.cat, a.ratificacion as ratificacioncontrato, a.residual as valorresidual, a.opcion_comp as opcioncompra,
	0.0 as totalpago, 
	ISNULL(a.n_precio,0) * (ISNULL(q.evm,0)/100) as evm,
	'' as descripcionPaqueteSubsidio, --0 as subsidiomontoDealer, 0 as subsidiomontoTMEX,
	--subsidiomontoDealer
	[dbo].[getSubsidioCotizacionActorSubsidio] (a.id_cotizacion,r.des_plazo,1,2) + [dbo].[getSubsidioCotizacionActorSubsidio] (a.id_cotizacion,r.des_plazo,1,4) as subsidiomontoDealer,
	--subsidiomontoTMEX
	[dbo].[getSubsidioCotizacionActorSubsidio] (a.id_cotizacion,r.des_plazo,2,2) + [dbo].[getSubsidioCotizacionActorSubsidio] (a.id_cotizacion,r.des_plazo,2,4) as subsidiomontoTMEX,
	g.descripcion as aseguradora, a.seg_danos as segurodedanos, a.seg_danos * ((a.iva/100)) as montoivasegdanos,
	h.gap as montoVF , h.gap / (1 +(a.iva/100)) as montosVFiniva, h.gap * ((a.iva/100)) as ivamontoVF,
	a.seg_vida as segurodevida, i.descripcion as descripcionPE, a.garantia as montoPE,
	a.rc_extranjera as rcext, a.seg_danos + a.seg_vida+ a.rc_extranjera as totseguros,
	j.descripcion as cobertura, k.des_uso as uso, l.descripcion as tipopago, a.id_seg_anual as anual,
	m.descripcion as edocirculacion,
	s.fec_limite as fechaLimiteCompra,
	a.is_usado as esUsado,
	case when a.is_usado =1 then 
		case when a.des_autou like '%SUBARU%' then 
			'SUBARU'
		else
			t.descripcion
		end
	else
		t.descripcion
	end as marca
	/*
	case when d.id_tipo_plan = 6 then 
         		isnull(a.renta,0) * (1+a.iva/100) * (isnull(a.pago_ap,0)+isnull(a.pago_seguro,0))
         else
         		isnull(a.renta,0) * isnull(a.pago_ap,0)
         end as depositogarantia,*/
	
	from bd_cotizacion a
		inner join cat_persona b on a.id_persona = b.id_persona
		inner join usuarios c on c.id_usuario = a.reg_alta
		inner join cat_promociones d on d.id_promocion = a.id_promocion
		inner join cat_tipo_plan e on e.id_tipo_plan = d.id_tipo_plan
		inner join cat_categoria_promocion f on d.id_categoria = f.id_categoria
		inner join cat_aseguradora g on g.id_aseguradora = a.id_aseguradora
		inner join gap h on h.id_cotizacion = a.id_cotizacion
		inner join cat_garantia i on i.id_garantia = a.id_garantia
		inner join cat_cobertura j on j.id_cobertura = a.n_cobertura
		inner join cat_uso k on k.id_uso = a.id_uso
		inner join cat_pago l on l.id_pago = a.id_pago
		inner join cat_estados m on m.id_estado = a.id_estado 
		INNER JOIN cat_auto n ON n.id_auto = a.id_auto
		INNER JOIN modelo o ON o.id_modelo = a.id_modelo
		INNER JOIN tipo p ON p.id_tipo = a.id_tipo
		LEFT JOIN prom_plazo q ON (q.id_promocion = a.id_promocion AND q.id_plazo = a.n_plazo)
		LEFT OUTER JOIN cat_plazo r ON r.id_plazo = a.n_plazo
		LEFT JOIN prom_vigencia s on s.id_promocion = d.id_promocion
		INNER JOIN cat_marcas t ON a.id_marca = t.id_marca
	where 
	h.status = 1		--Status gap
	and d.id_status = 1 --Status cat_promocion
	--and (s.id_status = 1 OR s.id_status IS NULL)--Status prom_vigencia
	and a.id_cotizacion = @pidcotizacion 
	--for xml auto
	--FOR XML RAW ('cotizacion');
	--FOR XML RAW ('Employee'), ROOT;
	--FOR XML RAW ('informacionFinanciera'), ROOT ('cotizacion'), ELEMENTS;
	FOR XML RAW ('informacionFinanciera'), ROOT ('cotizacion'), ELEMENTS XSINIL ); 

IF @xml IS NULL 
BEGIN
	-- NO existe la COTIZACIÓN con promoción activa 
    --SET @xml = @xmlEmpty;
	SELECT @xmlEmpty as result
END
ELSE IF @tieneVigencia IS NULL 
BEGIN
	-- No tiene vigencia, por lo tanto tiene fecha indefinida
	SELECT @xml as result
END
ELSE 
BEGIN
	-- Tiene vigencia, validar fecha final y fecha Limite
	DECLARE @fechaFin DATETIME;

	SET @fechaFin = (SELECT fec_fin FROM prom_vigencia WHERE id_prom_vigencia =  @tieneVigencia and id_status = 1)

	IF (@fechaFin IS NOT NULL)
	BEGIN
		IF (CONVERT(date,GETDATE(),126) <= @fechaFin)
			SELECT @xml as result	--MUESTRA LA COTIZACIÓN CON LA INFO DE BD
		ELSE
			SELECT @xmlEmpty as result -- MUESTRA el XML vacío
			
	END
END

END
ELSE IF @coincideDealer = 0
BEGIN
	-- No coincide dealer
	SELECT @xmlEmpty as result
END

SET NOCOUNT OFF;	
END

--USE [BD_COT4]
--GO
--/****** Object:  StoredProcedure [dbo].[spGetInfoCotizacion]    Script Date: 18/01/2018 03:16:37 p.m. ******/
--SET ANSI_NULLS OFF
--GO
--SET QUOTED_IDENTIFIER ON
--GO


--ALTER proc [dbo].[spGetInfoCotizacion] (@pidcotizacion int )  as
--BEGIN
--SET NOCOUNT ON;	

--/*select a.id_cotizacion as numCotizacion,a.fec_alta as fechageneracion, b.descripcion as tipoPersona,
--	c.username as quiencotizo, d.descripcion as promocion, e.descripcion as tipoplan,
--	f.descripcion as categoriapromocion, a.n_tasa as tasa, a.enganche , a.garantia as depositoGarantia,
--	a.mon_fina as montoafinanciar, a.n_plazo as plazo, a.des_ini as desembolsoinicial, a.pago,a.pago / (1 +(a.iva/100)) as pagosinIva,
--	a.iva, a.comision_monto as comision, a.comision_monto / (1 +(a.iva/100)) as comisionsiniva,
--	a.acce_fin as accesoriosFinanciados, a.acce - a.acce_fin as accesoriosContado, a.acce as accesoriosTotales,
--	a.dia_ini + '-' + a.mes_ini+ '-' + a.ano_ini as fechaprimerpago, a.dia_fin + '-' + a.mes_fin + '-' + a.ano_fin as fechaultimopago,
--	a.n_balloon as balloon, a.monto_anualidad as montoAnualidad, a.mes_an as mesAnualidad, a.ultima,
--	a.cat, a.ratificacion as ratificacioncontrato, a.residual as valorresidual, a.opcion_comp as opcioncompra,
--	0.0 as totalpago, '' as descripcionPaqueteSubsidio, 0 as subsidiomontoDealer, 0 as subsidiomontoTMEX,
--	g.descripcion as aseguradora, a.seg_danos as segurodedanos, a.seg_danos * ((a.iva/100)) as montoivasegdanos,
--	h.gap as montoVF , h.gap / (1 +(a.iva/100)) as montosVFiniva, h.gap * ((a.iva/100)) as ivamontoVF,
--	a.seg_vida as segurodevida, i.descripcion as descripcionPE, a.garantia as montoPE,
--	a.rc_extranjera as rcext, a.seg_danos + a.seg_vida+ a.rc_extranjera as totseguros,
--	j.descripcion as cobertura, k.des_uso as uso, l.descripcion as tipopago, a.id_seg_anual as anual,
--	m.descripcion as edocirculacion
--	from bd_cotizacion a
--		inner join cat_persona b on a.id_persona = b.id_persona
--		inner join usuarios c on c.id_usuario = a.reg_alta
--		inner join cat_promociones d on d.id_promocion = a.id_promocion
--		inner join cat_tipo_plan e on e.id_tipo_plan = d.id_tipo_plan
--		inner join cat_categoria_promocion f on d.id_categoria = f.id_categoria
--		inner join cat_aseguradora g on g.id_aseguradora = a.id_aseguradora
--		inner join gap h on h.id_cotizacion = a.id_cotizacion
--		inner join cat_garantia i on i.id_garantia = a.id_garantia
--		inner join cat_cobertura j on j.id_cobertura = a.n_cobertura
--		inner join cat_uso k on k.id_uso = a.id_uso
--		inner join cat_pago l on l.id_pago = a.id_pago
--		inner join cat_estados m on m.id_estado = a.id_estado 
--	where h.status = 1
--	and a.id_cotizacion = @pidcotizacion
--*/
--DECLARE @xml XML = (
--select a.id_cotizacion as numCotizacion,a.fec_alta as fechageneracion, b.descripcion as tipoPersona,
--	c.nombre+' '+ISNULL(c.paterno,'')+' '+ISNULL(c.materno,' ') as quiencotizo, 
--	n.des_auto as auto,
--	p.descripcion as version,
--	o.descripcion as modelo,
--	a.n_precio as precio,
--	d.descripcion as promocion, 
--	e.id_tipo_plan as idtipoplan,
--	e.descripcion as tipoplan,
--	f.descripcion as categoriapromocion, a.n_tasa as tasa, a.enganche , 
--	case when d.id_tipo_plan = 6
--			then 
--         		isnull(a.renta,0) * (1+a.iva/100) * (isnull(a.pago_ap,0)+isnull(a.pago_seguro,0))
--         	else
--         		isnull(a.renta,0) * isnull(a.pago_ap,0)
--         	end as depositoGarantia,
--	a.renta as numrentasdeposito,
--	--a.garantia as depositoGarantia,
--	a.mon_fina as montoafinanciar, a.n_plazo as plazo, a.des_ini as desembolsoinicial, a.pago,a.pago / (1 +(a.iva/100)) as pagosinIva,
--	a.iva, a.comision_monto as comision, 
--	--a.comision as por_comision,
--	a.comision_monto / (1 +(a.iva/100)) as comisionsiniva,
--	a.acce_fin as accesoriosFinanciados, a.acce - a.acce_fin as accesoriosContado, a.acce as accesoriosTotales, a.id_periodicidad as periodicidadPago,
--	CONVERT(VARCHAR(2), a.dia_ini) + '-' + CONVERT(VARCHAR(2), a.mes_ini) + '-' + CONVERT(VARCHAR(4), a.ano_ini)
--	as fechaprimerpago, 
--	CONVERT(VARCHAR(2), a.dia_fin) + '-' + CONVERT(VARCHAR(2), a.mes_fin) + '-' + CONVERT(VARCHAR(4), a.ano_fin)
--	as fechaultimopago,
--	a.n_balloon as balloon, a.monto_anualidad as montoAnualidad, a.mes_an as mesAnualidad, a.ultima,
--	a.cat, a.ratificacion as ratificacioncontrato, a.residual as valorresidual, a.opcion_comp as opcioncompra,
--	0.0 as totalpago, 
--	ISNULL(a.n_precio,0) * (ISNULL(q.evm,0)/100) as evm,
--	'' as descripcionPaqueteSubsidio, --0 as subsidiomontoDealer, 0 as subsidiomontoTMEX,
--	--subsidiomontoDealer
--	[dbo].[getSubsidioCotizacionActorSubsidio] (a.id_cotizacion,r.des_plazo,1,2) + [dbo].[getSubsidioCotizacionActorSubsidio] (a.id_cotizacion,r.des_plazo,1,4) as subsidiomontoDealer,
--	--subsidiomontoTMEX
--	[dbo].[getSubsidioCotizacionActorSubsidio] (a.id_cotizacion,r.des_plazo,2,2) + [dbo].[getSubsidioCotizacionActorSubsidio] (a.id_cotizacion,r.des_plazo,2,4) as subsidiomontoTMEX,
--	g.descripcion as aseguradora, a.seg_danos as segurodedanos, a.seg_danos * ((a.iva/100)) as montoivasegdanos,
--	h.gap as montoVF , h.gap / (1 +(a.iva/100)) as montosVFiniva, h.gap * ((a.iva/100)) as ivamontoVF,
--	a.seg_vida as segurodevida, i.descripcion as descripcionPE, a.garantia as montoPE,
--	a.rc_extranjera as rcext, a.seg_danos + a.seg_vida+ a.rc_extranjera as totseguros,
--	j.descripcion as cobertura, k.des_uso as uso, l.descripcion as tipopago, a.id_seg_anual as anual,
--	m.descripcion as edocirculacion
--	/*
--	case when d.id_tipo_plan = 6 then 
--         		isnull(a.renta,0) * (1+a.iva/100) * (isnull(a.pago_ap,0)+isnull(a.pago_seguro,0))
--         else
--         		isnull(a.renta,0) * isnull(a.pago_ap,0)
--         end as depositogarantia,*/
	
--	from bd_cotizacion a
--		inner join cat_persona b on a.id_persona = b.id_persona
--		inner join usuarios c on c.id_usuario = a.reg_alta
--		inner join cat_promociones d on d.id_promocion = a.id_promocion
--		inner join cat_tipo_plan e on e.id_tipo_plan = d.id_tipo_plan
--		inner join cat_categoria_promocion f on d.id_categoria = f.id_categoria
--		inner join cat_aseguradora g on g.id_aseguradora = a.id_aseguradora
--		inner join gap h on h.id_cotizacion = a.id_cotizacion
--		inner join cat_garantia i on i.id_garantia = a.id_garantia
--		inner join cat_cobertura j on j.id_cobertura = a.n_cobertura
--		inner join cat_uso k on k.id_uso = a.id_uso
--		inner join cat_pago l on l.id_pago = a.id_pago
--		inner join cat_estados m on m.id_estado = a.id_estado 
--		INNER JOIN cat_auto n ON n.id_auto = a.id_auto
--		INNER JOIN modelo o ON o.id_modelo = a.id_modelo
--		INNER JOIN tipo p ON p.id_tipo = a.id_tipo
--		LEFT JOIN prom_plazo q ON (q.id_promocion = a.id_promocion AND q.id_plazo = a.n_plazo)
--		LEFT OUTER JOIN cat_plazo r ON r.id_plazo = a.n_plazo
--	where h.status = 1
--	and a.id_cotizacion = @pidcotizacion
--	--for xml auto
--	--FOR XML RAW ('cotizacion');
--	--FOR XML RAW ('Employee'), ROOT;
--	--FOR XML RAW ('informacionFinanciera'), ROOT ('cotizacion'), ELEMENTS;
--	FOR XML RAW ('informacionFinanciera'), ROOT ('cotizacion'), ELEMENTS XSINIL ); 


--IF @xml IS NULL 
--    SET @xml = N'<cotizacion>
--	<informacionFinanciera>
--		<numCotizacion></numCotizacion>
--		<fechageneracion></fechageneracion>
--		<tipoPersona></tipoPersona>
--		<quiencotizo></quiencotizo>
--		<auto></auto>
--		<version></version>
--		<modelo></modelo>
--		<precio></precio>
--		<promocion></promocion>
--		<idtipoplan></idtipoplan>
--		<tipoplan></tipoplan>
--		<categoriapromocion></categoriapromocion>
--		<tasa></tasa>
--		<enganche></enganche>
--		<depositoGarantia></depositoGarantia>
--		<numrentasdeposito></numrentasdeposito>
--		<montoafinanciar></montoafinanciar>
--		<plazo></plazo>
--		<desembolsoinicial></desembolsoinicial>
--		<pago></pago>
--		<pagosinIva></pagosinIva>
--		<iva></iva>
--		<comision></comision>
--		<por_comision></por_comision>
--		<comisionsiniva></comisionsiniva>
--		<accesoriosFinanciados></accesoriosFinanciados>
--		<accesoriosContado></accesoriosContado>
--		<accesoriosTotales></accesoriosTotales>
--		<periodicidadPago></periodicidadPago>
--		<fechaprimerpago></fechaprimerpago>
--		<fechaultimopago></fechaultimopago>
--		<balloon></balloon>
--		<montoAnualidad></montoAnualidad>
--		<mesAnualidad></mesAnualidad>
--		<ultima></ultima>
--		<cat></cat>
--		<ratificacioncontrato></ratificacioncontrato>
--		<valorresidual></valorresidual>
--		<opcioncompra></opcioncompra>
--		<totalpago></totalpago>
--		<evm></evm>
--		<descripcionPaqueteSubsidio></descripcionPaqueteSubsidio>
--		<subsidiomontoDealer></subsidiomontoDealer>
--		<subsidiomontoTMEX></subsidiomontoTMEX>
--		<aseguradora></aseguradora>
--		<segurodedanos></segurodedanos>
--		<montoivasegdanos></montoivasegdanos>
--		<montoVF></montoVF >
--		<montosVFiniva></montosVFiniva >
--		<ivamontoVF></ivamontoVF >
--		<segurodevida></segurodevida>
--		<descripcionPE></descripcionPE >
--		<montoPE></montoPE>
--		<rcext></rcext>
--		<totseguros></totseguros>
--		<cobertura></cobertura>
--		<uso></uso>
--		<tipopago></tipopago>
--		<anual></anual>
--		<edocirculacion></edocirculacion>
--	</informacionFinanciera>
--</cotizacion>
--'

--SELECT @xml as result

--SET NOCOUNT OFF;	
--END




----USE [BD_COT4]
----GO
----/****** Object:  StoredProcedure [dbo].[spGetInfoCotizacion]    Script Date: 11/01/2018 04:03:26 p.m. ******/
----SET ANSI_NULLS OFF
----GO
----SET QUOTED_IDENTIFIER ON
----GO


----ALTER proc [dbo].[spGetInfoCotizacion] (@pidcotizacion int )  as
----BEGIN
----SET NOCOUNT ON;	

----/*select a.id_cotizacion as numCotizacion,a.fec_alta as fechageneracion, b.descripcion as tipoPersona,
----	c.username as quiencotizo, d.descripcion as promocion, e.descripcion as tipoplan,
----	f.descripcion as categoriapromocion, a.n_tasa as tasa, a.enganche , a.garantia as depositoGarantia,
----	a.mon_fina as montoafinanciar, a.n_plazo as plazo, a.des_ini as desembolsoinicial, a.pago,a.pago / (1 +(a.iva/100)) as pagosinIva,
----	a.iva, a.comision_monto as comision, a.comision_monto / (1 +(a.iva/100)) as comisionsiniva,
----	a.acce_fin as accesoriosFinanciados, a.acce - a.acce_fin as accesoriosContado, a.acce as accesoriosTotales,
----	a.dia_ini + '-' + a.mes_ini+ '-' + a.ano_ini as fechaprimerpago, a.dia_fin + '-' + a.mes_fin + '-' + a.ano_fin as fechaultimopago,
----	a.n_balloon as balloon, a.monto_anualidad as montoAnualidad, a.mes_an as mesAnualidad, a.ultima,
----	a.cat, a.ratificacion as ratificacioncontrato, a.residual as valorresidual, a.opcion_comp as opcioncompra,
----	0.0 as totalpago, '' as descripcionPaqueteSubsidio, 0 as subsidiomontoDealer, 0 as subsidiomontoTMEX,
----	g.descripcion as aseguradora, a.seg_danos as segurodedanos, a.seg_danos * ((a.iva/100)) as montoivasegdanos,
----	h.gap as montoVF , h.gap / (1 +(a.iva/100)) as montosVFiniva, h.gap * ((a.iva/100)) as ivamontoVF,
----	a.seg_vida as segurodevida, i.descripcion as descripcionPE, a.garantia as montoPE,
----	a.rc_extranjera as rcext, a.seg_danos + a.seg_vida+ a.rc_extranjera as totseguros,
----	j.descripcion as cobertura, k.des_uso as uso, l.descripcion as tipopago, a.id_seg_anual as anual,
----	m.descripcion as edocirculacion
----	from bd_cotizacion a
----		inner join cat_persona b on a.id_persona = b.id_persona
----		inner join usuarios c on c.id_usuario = a.reg_alta
----		inner join cat_promociones d on d.id_promocion = a.id_promocion
----		inner join cat_tipo_plan e on e.id_tipo_plan = d.id_tipo_plan
----		inner join cat_categoria_promocion f on d.id_categoria = f.id_categoria
----		inner join cat_aseguradora g on g.id_aseguradora = a.id_aseguradora
----		inner join gap h on h.id_cotizacion = a.id_cotizacion
----		inner join cat_garantia i on i.id_garantia = a.id_garantia
----		inner join cat_cobertura j on j.id_cobertura = a.n_cobertura
----		inner join cat_uso k on k.id_uso = a.id_uso
----		inner join cat_pago l on l.id_pago = a.id_pago
----		inner join cat_estados m on m.id_estado = a.id_estado 
----	where h.status = 1
----	and a.id_cotizacion = @pidcotizacion
----*/
----DECLARE @xml XML = (
----select a.id_cotizacion as numCotizacion,a.fec_alta as fechageneracion, b.descripcion as tipoPersona,
----	c.username as quiencotizo, d.descripcion as promocion, e.descripcion as tipoplan,
----	f.descripcion as categoriapromocion, a.n_tasa as tasa, a.enganche , a.garantia as depositoGarantia,
----	a.mon_fina as montoafinanciar, a.n_plazo as plazo, a.des_ini as desembolsoinicial, a.pago,a.pago / (1 +(a.iva/100)) as pagosinIva,
----	a.iva, a.comision_monto as comision, a.comision_monto / (1 +(a.iva/100)) as comisionsiniva,
----	a.acce_fin as accesoriosFinanciados, a.acce - a.acce_fin as accesoriosContado, a.acce as accesoriosTotales, a.id_periodicidad as periodicidadPago,
----	a.dia_ini + '-' + a.mes_ini+ '-' + a.ano_ini as fechaprimerpago, a.dia_fin + '-' + a.mes_fin + '-' + a.ano_fin as fechaultimopago,
----	a.n_balloon as balloon, a.monto_anualidad as montoAnualidad, a.mes_an as mesAnualidad, a.ultima,
----	a.cat, a.ratificacion as ratificacioncontrato, a.residual as valorresidual, a.opcion_comp as opcioncompra,
----	0.0 as totalpago, '' as descripcionPaqueteSubsidio, 0 as subsidiomontoDealer, 0 as subsidiomontoTMEX,
----	g.descripcion as aseguradora, a.seg_danos as segurodedanos, a.seg_danos * ((a.iva/100)) as montoivasegdanos,
----	h.gap as montoVF , h.gap / (1 +(a.iva/100)) as montosVFiniva, h.gap * ((a.iva/100)) as ivamontoVF,
----	a.seg_vida as segurodevida, i.descripcion as descripcionPE, a.garantia as montoPE,
----	a.rc_extranjera as rcext, a.seg_danos + a.seg_vida+ a.rc_extranjera as totseguros,
----	j.descripcion as cobertura, k.des_uso as uso, l.descripcion as tipopago, a.id_seg_anual as anual,
----	m.descripcion as edocirculacion
----	from bd_cotizacion a
----		inner join cat_persona b on a.id_persona = b.id_persona
----		inner join usuarios c on c.id_usuario = a.reg_alta
----		inner join cat_promociones d on d.id_promocion = a.id_promocion
----		inner join cat_tipo_plan e on e.id_tipo_plan = d.id_tipo_plan
----		inner join cat_categoria_promocion f on d.id_categoria = f.id_categoria
----		inner join cat_aseguradora g on g.id_aseguradora = a.id_aseguradora
----		inner join gap h on h.id_cotizacion = a.id_cotizacion
----		inner join cat_garantia i on i.id_garantia = a.id_garantia
----		inner join cat_cobertura j on j.id_cobertura = a.n_cobertura
----		inner join cat_uso k on k.id_uso = a.id_uso
----		inner join cat_pago l on l.id_pago = a.id_pago
----		inner join cat_estados m on m.id_estado = a.id_estado 
----	where h.status = 1
----	and a.id_cotizacion = @pidcotizacion
----	--for xml auto
----	--FOR XML RAW ('cotizacion');
----	--FOR XML RAW ('Employee'), ROOT;
----	--FOR XML RAW ('informacionFinanciera'), ROOT ('cotizacion'), ELEMENTS;
----	FOR XML RAW ('informacionFinanciera'), ROOT ('cotizacion'), ELEMENTS XSINIL ); 


----IF @xml IS NULL 
----    SET @xml = N'<cotizacion>
----	<informacionFinanciera>
----		<numCotizacion></numCotizacion>
----		<fechageneracion></fechageneracion>
----		<tipoPersona></tipoPersona>
----		<quiencotizo></quiencotizo>
----		<promocion></promocion>
----		<tipoplan></tipoplan>
----		<categoriapromocion></categoriapromocion>
----		<tasa></tasa>
----		<enganche></enganche>
----		<depositoGarantia></depositoGarantia>
----		<montoafinanciar></montoafinanciar>
----		<plazo></plazo>
----		<desembolsoinicial></desembolsoinicial>
----		<pago></pago>
----		<pagosinIva></pagosinIva>
----		<iva></iva>
----		<comision></comision>
----		<comisionsiniva></comisionsiniva>
----		<accesoriosFinanciados></accesoriosFinanciados>
----		<accesoriosContado></accesoriosContado>
----		<accesoriosTotales></accesoriosTotales>
----		<periodicidadPago></periodicidadPago>
----		<fechaprimerpago></fechaprimerpago>
----		<fechaultimopago></fechaultimopago>
----		<balloon></balloon>
----		<montoAnualidad></montoAnualidad>
----		<mesAnualidad></mesAnualidad>
----		<ultima></ultima>
----		<cat></cat>
----		<ratificacioncontrato></ratificacioncontrato>
----		<valorresidual></valorresidual>
----		<opcioncompra></opcioncompra>
----		<totalpago></totalpago>
----		<descripcionPaqueteSubsidio></descripcionPaqueteSubsidio>
----		<subsidiomontoDealer></subsidiomontoDealer>
----		<subsidiomontoTMEX></subsidiomontoTMEX>
----		<aseguradora></aseguradora>
----		<segurodedanos></segurodedanos>
----		<montoivasegdanos></montoivasegdanos>
----		<montoVF></montoVF >
----		<montosVFiniva></montosVFiniva >
----		<ivamontoVF></ivamontoVF >
----		<segurodevida></segurodevida>
----		<descripcionPE></descripcionPE >
----		<montoPE></montoPE>
----		<rcext></rcext>
----		<totseguros></totseguros>
----		<cobertura></cobertura>
----		<uso></uso>
----		<tipopago></tipopago>
----		<anual></anual>
----		<edocirculacion></edocirculacion>
----	</informacionFinanciera>
----</cotizacion>
----'

----SELECT @xml as result

----SET NOCOUNT OFF;	
----END