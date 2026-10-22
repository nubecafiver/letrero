*&---------------------------------------------------------------------*
*& Report  Z_VA05_EXT
*& Clon de VA05 (lista de pedidos de venta) con columnas adicionales
*& de la pestana "Datos de pedido" (cabecera y posicion).
*& Transaccion sugerida: ZVA05 (SE93 -> transaccion de reporte)
*&---------------------------------------------------------------------*
REPORT z_va05_ext.

TABLES: vbak, vbap, kna1, vbuk.

TYPES: BEGIN OF ty_out,
         vbeln     TYPE vbak-vbeln,
         posnr     TYPE vbap-posnr,
         auart     TYPE vbak-auart,
         erdat     TYPE vbak-erdat,
         ernam     TYPE vbak-ernam,
         vkorg     TYPE vbak-vkorg,
         vtweg     TYPE vbak-vtweg,
         spart     TYPE vbak-spart,
         vkbur     TYPE vbak-vkbur,
         kunnr     TYPE vbak-kunnr,
         name1     TYPE kna1-name1,
         matnr     TYPE vbap-matnr,
         arktx     TYPE vbap-arktx,
         kwmeng    TYPE vbap-kwmeng,
         vrkme     TYPE vbap-vrkme,
         netwr     TYPE vbap-netwr,
         waerk     TYPE vbak-waerk,
         gbstk     TYPE vbuk-gbstk,
         " --- Cabecera: Datos de pedido / Solicitante
         h_bstkd   TYPE vbkd-bstkd,
         h_bstdk   TYPE vbkd-bstdk,
         h_bsark   TYPE vbkd-bsark,
         h_ihrez   TYPE vbkd-ihrez,
         h_bname   TYPE vbak-bname,
         h_telf1   TYPE vbak-telf1,
         " --- Cabecera: Destinatario de mercancias
         h_bstkd_e TYPE vbkd-bstkd_e,
         h_bstdk_e TYPE vbkd-bstdk_e,
         h_bsark_e TYPE vbkd-bsark_e,
         h_ihrez_e TYPE vbkd-ihrez_e,
         " --- Posicion: Solicitante
         p_bstkd   TYPE vbkd-bstkd,
         p_bstdk   TYPE vbkd-bstdk,
         p_bsark   TYPE vbkd-bsark,
         p_posex   TYPE vbap-posex,
         p_ihrez   TYPE vbkd-ihrez,
         p_ihrez_e TYPE vbkd-ihrez_e,
         p_kdmat   TYPE vbap-kdmat,
         " --- Posicion: Destinatario de mercancias
         p_bstkd_e TYPE vbkd-bstkd_e,
         p_bstdk_e TYPE vbkd-bstdk_e,
         p_bsark_e TYPE vbkd-bsark_e,
         p_posex_e TYPE vbkd-posex_e,
       END OF ty_out.

DATA: gt_out TYPE STANDARD TABLE OF ty_out,
      gs_out TYPE ty_out.

*---------------------------------------------------------------------*
* Pantalla de seleccion (equivalente a VA05)
*---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
SELECT-OPTIONS: s_kunnr FOR vbak-kunnr,
                s_matnr FOR vbap-matnr,
                s_vbeln FOR vbak-vbeln,
                s_bstnk FOR vbak-bstnk,
                s_auart FOR vbak-auart,
                s_erdat FOR vbak-erdat,
                s_audat FOR vbak-audat,
                s_ernam FOR vbak-ernam,
                s_vkorg FOR vbak-vkorg,
                s_vtweg FOR vbak-vtweg,
                s_spart FOR vbak-spart,
                s_vkbur FOR vbak-vkbur.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
SELECT-OPTIONS: s_gbstk FOR vbuk-gbstk.
SELECTION-SCREEN END OF BLOCK b2.

START-OF-SELECTION.
  PERFORM get_data.
  PERFORM show_alv.

*---------------------------------------------------------------------*
FORM get_data.
  DATA: lt_vbak TYPE SORTED TABLE OF vbak WITH UNIQUE KEY vbeln,
        lt_vbap TYPE STANDARD TABLE OF vbap,
        lt_vbuk TYPE SORTED TABLE OF vbuk WITH UNIQUE KEY vbeln,
        lt_vbkd TYPE SORTED TABLE OF vbkd WITH UNIQUE KEY vbeln posnr,
        lt_kna1 TYPE SORTED TABLE OF kna1 WITH UNIQUE KEY kunnr.
  FIELD-SYMBOLS: <vbap> TYPE vbap,
                 <vbak> TYPE vbak,
                 <vbuk> TYPE vbuk,
                 <kna1> TYPE kna1,
                 <vbkd> TYPE vbkd.

  SELECT * FROM vbak INTO TABLE lt_vbak
    WHERE vbeln IN s_vbeln
      AND kunnr IN s_kunnr
      AND bstnk IN s_bstnk
      AND auart IN s_auart
      AND erdat IN s_erdat
      AND audat IN s_audat
      AND ernam IN s_ernam
      AND vkorg IN s_vkorg
      AND vtweg IN s_vtweg
      AND spart IN s_spart
      AND vkbur IN s_vkbur.
  IF lt_vbak IS INITIAL.
    MESSAGE 'No hay pedidos en VBAK con esa seleccion' TYPE 'I'.
    RETURN.
  ENDIF.

  SELECT * FROM vbap INTO TABLE lt_vbap
    FOR ALL ENTRIES IN lt_vbak
    WHERE vbeln = lt_vbak-vbeln
      AND matnr IN s_matnr.
  IF lt_vbap IS INITIAL.
    MESSAGE 'Hay pedidos en VBAK pero ninguna posicion en VBAP con ese material' TYPE 'I'.
    RETURN.
  ENDIF.

  SELECT * FROM vbuk INTO TABLE lt_vbuk
    FOR ALL ENTRIES IN lt_vbak
    WHERE vbeln = lt_vbak-vbeln.

  SELECT * FROM vbkd INTO TABLE lt_vbkd
    FOR ALL ENTRIES IN lt_vbak
    WHERE vbeln = lt_vbak-vbeln.

  SELECT * FROM kna1 INTO TABLE lt_kna1
    FOR ALL ENTRIES IN lt_vbak
    WHERE kunnr = lt_vbak-kunnr.

  LOOP AT lt_vbap ASSIGNING <vbap>.
    CLEAR gs_out.
    READ TABLE lt_vbak ASSIGNING <vbak> WITH TABLE KEY vbeln = <vbap>-vbeln.
    CHECK sy-subrc = 0.

    READ TABLE lt_vbuk ASSIGNING <vbuk> WITH TABLE KEY vbeln = <vbap>-vbeln.
    IF sy-subrc = 0.
      gs_out-gbstk = <vbuk>-gbstk.
    ENDIF.
    " Filtro por StatusGlob (A = abierto, B = parcial, C = completo)
    IF gs_out-gbstk NOT IN s_gbstk. CONTINUE. ENDIF.

    gs_out-vbeln  = <vbap>-vbeln.
    gs_out-posnr  = <vbap>-posnr.
    gs_out-auart  = <vbak>-auart.
    gs_out-erdat  = <vbak>-erdat.
    gs_out-ernam  = <vbak>-ernam.
    gs_out-vkorg  = <vbak>-vkorg.
    gs_out-vtweg  = <vbak>-vtweg.
    gs_out-spart  = <vbak>-spart.
    gs_out-vkbur  = <vbak>-vkbur.
    gs_out-kunnr  = <vbak>-kunnr.
    gs_out-waerk  = <vbak>-waerk.
    gs_out-matnr  = <vbap>-matnr.
    gs_out-arktx  = <vbap>-arktx.
    gs_out-kwmeng = <vbap>-kwmeng.
    gs_out-vrkme  = <vbap>-vrkme.
    gs_out-netwr  = <vbap>-netwr.

    READ TABLE lt_kna1 ASSIGNING <kna1> WITH TABLE KEY kunnr = <vbak>-kunnr.
    IF sy-subrc = 0.
      gs_out-name1 = <kna1>-name1.
    ENDIF.

    " --- Cabecera (VBKD posicion 000000)
    gs_out-h_bname = <vbak>-bname.
    gs_out-h_telf1 = <vbak>-telf1.
    READ TABLE lt_vbkd ASSIGNING <vbkd>
         WITH TABLE KEY vbeln = <vbap>-vbeln posnr = '000000'.
    IF sy-subrc = 0.
      gs_out-h_bstkd   = <vbkd>-bstkd.
      gs_out-h_bstdk   = <vbkd>-bstdk.
      gs_out-h_bsark   = <vbkd>-bsark.
      gs_out-h_ihrez   = <vbkd>-ihrez.
      gs_out-h_bstkd_e = <vbkd>-bstkd_e.
      gs_out-h_bstdk_e = <vbkd>-bstdk_e.
      gs_out-h_bsark_e = <vbkd>-bsark_e.
      gs_out-h_ihrez_e = <vbkd>-ihrez_e.
    ENDIF.

    " --- Posicion (VBKD por posicion; si no existe, hereda de cabecera)
    gs_out-p_posex = <vbap>-posex.
    gs_out-p_kdmat = <vbap>-kdmat.
    READ TABLE lt_vbkd ASSIGNING <vbkd>
         WITH TABLE KEY vbeln = <vbap>-vbeln posnr = <vbap>-posnr.
    IF sy-subrc <> 0.
      READ TABLE lt_vbkd ASSIGNING <vbkd>
           WITH TABLE KEY vbeln = <vbap>-vbeln posnr = '000000'.
    ENDIF.
    IF sy-subrc = 0.
      gs_out-p_bstkd   = <vbkd>-bstkd.
      gs_out-p_bstdk   = <vbkd>-bstdk.
      gs_out-p_bsark   = <vbkd>-bsark.
      gs_out-p_ihrez   = <vbkd>-ihrez.
      gs_out-p_bstkd_e = <vbkd>-bstkd_e.
      gs_out-p_bstdk_e = <vbkd>-bstdk_e.
      gs_out-p_bsark_e = <vbkd>-bsark_e.
      gs_out-p_posex_e = <vbkd>-posex_e.
      gs_out-p_ihrez_e = <vbkd>-ihrez_e.
    ENDIF.

    APPEND gs_out TO gt_out.
  ENDLOOP.

  SORT gt_out BY vbeln posnr.
  IF gt_out IS INITIAL.
    MESSAGE 'Se descartaron todos los registros por el filtro de StatusGlob' TYPE 'I'.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
FORM show_alv.
  DATA: lo_alv  TYPE REF TO cl_salv_table,
        lo_cols TYPE REF TO cl_salv_columns_table,
        lo_func TYPE REF TO cl_salv_functions_list,
        lo_disp TYPE REF TO cl_salv_display_settings,
        lx      TYPE REF TO cx_root,
        lv_msg  TYPE string.

  IF gt_out IS INITIAL.
    RETURN.
  ENDIF.

  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = lo_alv
                              CHANGING  t_table      = gt_out ).
      lo_func = lo_alv->get_functions( ).
      lo_func->set_all( abap_true ).
      lo_disp = lo_alv->get_display_settings( ).
      lo_disp->set_list_header( 'Pedidos de venta (VA05 ext.)' ).
      lo_disp->set_striped_pattern( abap_true ).
      lo_cols = lo_alv->get_columns( ).
      lo_cols->set_optimize( abap_true ).

      PERFORM set_title USING lo_cols 'H_BSTKD'   'Cab: N pedido cliente'.
      PERFORM set_title USING lo_cols 'H_BSTDK'   'Cab: Fecha pedido'.
      PERFORM set_title USING lo_cols 'H_BSARK'   'Cab: Clase pedido'.
      PERFORM set_title USING lo_cols 'H_IHREZ'   'Cab: Referencia'.
      PERFORM set_title USING lo_cols 'H_BNAME'   'Cab: Nombre'.
      PERFORM set_title USING lo_cols 'H_TELF1'   'Cab: Telefono'.
      PERFORM set_title USING lo_cols 'H_BSTKD_E' 'Cab Dest: N pedido cliente'.
      PERFORM set_title USING lo_cols 'H_BSTDK_E' 'Cab Dest: Fecha pedido'.
      PERFORM set_title USING lo_cols 'H_BSARK_E' 'Cab Dest: Clase pedido'.
      PERFORM set_title USING lo_cols 'H_IHREZ_E' 'Cab Dest: Referencia'.
      PERFORM set_title USING lo_cols 'P_BSTKD'   'Pos: N pedido cliente'.
      PERFORM set_title USING lo_cols 'P_BSTDK'   'Pos: Fecha pedido'.
      PERFORM set_title USING lo_cols 'P_BSARK'   'Pos: Clase pedido'.
      PERFORM set_title USING lo_cols 'P_POSEX'   'Pos: Posicion pedido'.
      PERFORM set_title USING lo_cols 'P_IHREZ'   'Pos: Referencia'.
      PERFORM set_title USING lo_cols 'P_IHREZ_E' 'Pos Dest: Referencia'.
      PERFORM set_title USING lo_cols 'P_KDMAT'   'Pos: Material cliente'.
      PERFORM set_title USING lo_cols 'P_BSTKD_E' 'Pos Dest: N pedido cliente'.
      PERFORM set_title USING lo_cols 'P_BSTDK_E' 'Pos Dest: Fecha pedido'.
      PERFORM set_title USING lo_cols 'P_BSARK_E' 'Pos Dest: Clase pedido'.
      PERFORM set_title USING lo_cols 'P_POSEX_E' 'Pos Dest: Posicion pedido'.

      lo_alv->display( ).
    CATCH cx_root INTO lx.
      lv_msg = lx->get_text( ).
      MESSAGE lv_msg TYPE 'E'.
  ENDTRY.
ENDFORM.

FORM set_title USING io_cols TYPE REF TO cl_salv_columns_table
                     iv_name TYPE lvc_fname
                     iv_text TYPE csequence.
  DATA: lo_col TYPE REF TO cl_salv_column,
        lv_l   TYPE scrtext_l,
        lv_m   TYPE scrtext_m,
        lv_s   TYPE scrtext_s.
  lv_l = iv_text.
  lv_m = iv_text.
  lv_s = iv_text.
  TRY.
      lo_col = io_cols->get_column( iv_name ).
      lo_col->set_long_text( lv_l ).
      lo_col->set_medium_text( lv_m ).
      lo_col->set_short_text( lv_s ).
    CATCH cx_salv_not_found.
  ENDTRY.
ENDFORM.
