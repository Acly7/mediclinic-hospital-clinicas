--
-- PostgreSQL database dump
--

\restrict yx3c2lcuxLjfnkbsBRuN9xWvIQQQ2F3g7K2clUV2h9G1PmE4TLfd4SfdtVp14lh

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

-- Started on 2026-06-06 22:49:41

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 5 (class 2615 OID 50002)
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- TOC entry 5190 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS '';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 256 (class 1259 OID 50446)
-- Name: archivos_clinicos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.archivos_clinicos (
    id integer NOT NULL,
    expediente_id integer NOT NULL,
    nombre_archivo character varying(180) NOT NULL,
    tipo_archivo character varying(80),
    storage_provider character varying(60) DEFAULT 'Almacenamiento local simulado'::character varying,
    storage_url text NOT NULL,
    descripcion text,
    subido_por integer,
    creado_en timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.archivos_clinicos OWNER TO postgres;

--
-- TOC entry 255 (class 1259 OID 50445)
-- Name: archivos_clinicos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.archivos_clinicos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.archivos_clinicos_id_seq OWNER TO postgres;

--
-- TOC entry 5192 (class 0 OID 0)
-- Dependencies: 255
-- Name: archivos_clinicos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.archivos_clinicos_id_seq OWNED BY public.archivos_clinicos.id;


--
-- TOC entry 234 (class 1259 OID 50155)
-- Name: citas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.citas (
    id integer NOT NULL,
    paciente_id integer NOT NULL,
    medico_id integer NOT NULL,
    especialidad_id integer NOT NULL,
    fecha date NOT NULL,
    hora time without time zone NOT NULL,
    motivo text,
    estado character varying(20) DEFAULT 'Pendiente'::character varying NOT NULL,
    creado_por integer,
    creado_en timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT citas_estado_check CHECK (((estado)::text = ANY ((ARRAY['Pendiente'::character varying, 'Confirmada'::character varying, 'Atendida'::character varying, 'Cancelada'::character varying])::text[])))
);


ALTER TABLE public.citas OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 50154)
-- Name: citas_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.citas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.citas_id_seq OWNER TO postgres;

--
-- TOC entry 5193 (class 0 OID 0)
-- Dependencies: 233
-- Name: citas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.citas_id_seq OWNED BY public.citas.id;


--
-- TOC entry 254 (class 1259 OID 50427)
-- Name: cola_mensajes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cola_mensajes (
    id integer NOT NULL,
    tipo character varying(80) NOT NULL,
    referencia_id integer,
    payload jsonb NOT NULL,
    estado character varying(20) DEFAULT 'Pendiente'::character varying NOT NULL,
    intentos integer DEFAULT 0 NOT NULL,
    creado_en timestamp without time zone DEFAULT now() NOT NULL,
    procesado_en timestamp without time zone,
    CONSTRAINT cola_mensajes_estado_check CHECK (((estado)::text = ANY ((ARRAY['Pendiente'::character varying, 'Procesado'::character varying, 'Error'::character varying])::text[])))
);


ALTER TABLE public.cola_mensajes OWNER TO postgres;

--
-- TOC entry 253 (class 1259 OID 50426)
-- Name: cola_mensajes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cola_mensajes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cola_mensajes_id_seq OWNER TO postgres;

--
-- TOC entry 5194 (class 0 OID 0)
-- Dependencies: 253
-- Name: cola_mensajes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cola_mensajes_id_seq OWNED BY public.cola_mensajes.id;


--
-- TOC entry 238 (class 1259 OID 50220)
-- Name: consultas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.consultas (
    id integer NOT NULL,
    expediente_id integer NOT NULL,
    cita_id integer,
    medico_id integer NOT NULL,
    fecha timestamp without time zone DEFAULT now() NOT NULL,
    diagnostico text NOT NULL,
    tratamiento text,
    observaciones text
);


ALTER TABLE public.consultas OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 50219)
-- Name: consultas_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.consultas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.consultas_id_seq OWNER TO postgres;

--
-- TOC entry 5195 (class 0 OID 0)
-- Dependencies: 237
-- Name: consultas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.consultas_id_seq OWNED BY public.consultas.id;


--
-- TOC entry 222 (class 1259 OID 50017)
-- Name: especialidades; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.especialidades (
    id integer NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion text,
    estado character varying(20) DEFAULT 'Activo'::character varying,
    CONSTRAINT especialidades_estado_check CHECK (((estado)::text = ANY ((ARRAY['Activo'::character varying, 'Inactivo'::character varying])::text[])))
);


ALTER TABLE public.especialidades OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 50016)
-- Name: especialidades_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.especialidades_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.especialidades_id_seq OWNER TO postgres;

--
-- TOC entry 5196 (class 0 OID 0)
-- Dependencies: 221
-- Name: especialidades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.especialidades_id_seq OWNED BY public.especialidades.id;


--
-- TOC entry 244 (class 1259 OID 50292)
-- Name: examenes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.examenes (
    id integer NOT NULL,
    consulta_id integer NOT NULL,
    tipo character varying(100) NOT NULL,
    descripcion text,
    resultado text,
    archivo_url text,
    fecha timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.examenes OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 50291)
-- Name: examenes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.examenes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.examenes_id_seq OWNER TO postgres;

--
-- TOC entry 5197 (class 0 OID 0)
-- Dependencies: 243
-- Name: examenes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.examenes_id_seq OWNED BY public.examenes.id;


--
-- TOC entry 236 (class 1259 OID 50197)
-- Name: expedientes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.expedientes (
    id integer NOT NULL,
    paciente_id integer NOT NULL,
    codigo character varying(30) NOT NULL,
    observaciones_generales text,
    creado_en timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.expedientes OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 50196)
-- Name: expedientes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.expedientes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.expedientes_id_seq OWNER TO postgres;

--
-- TOC entry 5198 (class 0 OID 0)
-- Dependencies: 235
-- Name: expedientes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.expedientes_id_seq OWNED BY public.expedientes.id;


--
-- TOC entry 230 (class 1259 OID 50113)
-- Name: horarios_medicos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.horarios_medicos (
    id integer NOT NULL,
    medico_id integer NOT NULL,
    dia_semana character varying(15) NOT NULL,
    hora_inicio time without time zone NOT NULL,
    hora_fin time without time zone NOT NULL,
    consultorio character varying(30)
);


ALTER TABLE public.horarios_medicos OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 50112)
-- Name: horarios_medicos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.horarios_medicos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.horarios_medicos_id_seq OWNER TO postgres;

--
-- TOC entry 5199 (class 0 OID 0)
-- Dependencies: 229
-- Name: horarios_medicos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.horarios_medicos_id_seq OWNED BY public.horarios_medicos.id;


--
-- TOC entry 258 (class 1259 OID 50472)
-- Name: logs_actividad; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.logs_actividad (
    id integer NOT NULL,
    usuario_id integer,
    modulo character varying(80) NOT NULL,
    accion character varying(120) NOT NULL,
    detalle text,
    creado_en timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.logs_actividad OWNER TO postgres;

--
-- TOC entry 257 (class 1259 OID 50471)
-- Name: logs_actividad_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.logs_actividad_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.logs_actividad_id_seq OWNER TO postgres;

--
-- TOC entry 5200 (class 0 OID 0)
-- Dependencies: 257
-- Name: logs_actividad_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.logs_actividad_id_seq OWNED BY public.logs_actividad.id;


--
-- TOC entry 232 (class 1259 OID 50130)
-- Name: medicamentos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.medicamentos (
    id integer NOT NULL,
    codigo character varying(30) NOT NULL,
    nombre character varying(120) NOT NULL,
    presentacion character varying(80),
    concentracion character varying(80),
    categoria character varying(80),
    precio numeric(10,2) DEFAULT 0 NOT NULL,
    stock integer DEFAULT 0 NOT NULL,
    stock_minimo integer DEFAULT 5 NOT NULL,
    fecha_vencimiento date,
    estado character varying(20) DEFAULT 'Disponible'::character varying NOT NULL,
    actualizado_en timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT medicamentos_estado_check CHECK (((estado)::text = ANY ((ARRAY['Disponible'::character varying, 'Bajo stock'::character varying, 'Agotado'::character varying, 'Vencido'::character varying])::text[]))),
    CONSTRAINT medicamentos_stock_check CHECK ((stock >= 0)),
    CONSTRAINT medicamentos_stock_minimo_check CHECK ((stock_minimo >= 0))
);


ALTER TABLE public.medicamentos OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 50129)
-- Name: medicamentos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.medicamentos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.medicamentos_id_seq OWNER TO postgres;

--
-- TOC entry 5201 (class 0 OID 0)
-- Dependencies: 231
-- Name: medicamentos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.medicamentos_id_seq OWNED BY public.medicamentos.id;


--
-- TOC entry 224 (class 1259 OID 50032)
-- Name: medicos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.medicos (
    id integer NOT NULL,
    especialidad_id integer NOT NULL,
    nombre character varying(80) NOT NULL,
    apellido character varying(80) NOT NULL,
    ci character varying(20) NOT NULL,
    correo character varying(120),
    telefono character varying(30),
    nro_matricula character varying(50),
    estado character varying(25) DEFAULT 'Disponible'::character varying NOT NULL,
    CONSTRAINT medicos_estado_check CHECK (((estado)::text = ANY ((ARRAY['Disponible'::character varying, 'No disponible'::character varying, 'Inactivo'::character varying])::text[])))
);


ALTER TABLE public.medicos OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 50031)
-- Name: medicos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.medicos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.medicos_id_seq OWNER TO postgres;

--
-- TOC entry 5202 (class 0 OID 0)
-- Dependencies: 223
-- Name: medicos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.medicos_id_seq OWNED BY public.medicos.id;


--
-- TOC entry 246 (class 1259 OID 50311)
-- Name: movimientos_stock; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.movimientos_stock (
    id integer NOT NULL,
    medicamento_id integer NOT NULL,
    tipo character varying(20) NOT NULL,
    cantidad integer NOT NULL,
    motivo text,
    usuario_id integer,
    creado_en timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT movimientos_stock_cantidad_check CHECK ((cantidad > 0)),
    CONSTRAINT movimientos_stock_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['Entrada'::character varying, 'Salida'::character varying, 'Ajuste'::character varying])::text[])))
);


ALTER TABLE public.movimientos_stock OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 50310)
-- Name: movimientos_stock_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.movimientos_stock_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.movimientos_stock_id_seq OWNER TO postgres;

--
-- TOC entry 5203 (class 0 OID 0)
-- Dependencies: 245
-- Name: movimientos_stock_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.movimientos_stock_id_seq OWNED BY public.movimientos_stock.id;


--
-- TOC entry 252 (class 1259 OID 50388)
-- Name: notificaciones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notificaciones (
    id integer NOT NULL,
    usuario_destino_id integer,
    paciente_id integer,
    cita_id integer,
    destinatario character varying(120) NOT NULL,
    asunto character varying(160) NOT NULL,
    mensaje text NOT NULL,
    canal character varying(30) DEFAULT 'Sistema interno'::character varying NOT NULL,
    estado character varying(20) DEFAULT 'Pendiente'::character varying NOT NULL,
    tipo character varying(80) DEFAULT 'SISTEMA'::character varying NOT NULL,
    leida boolean DEFAULT false NOT NULL,
    creado_en timestamp without time zone DEFAULT now() NOT NULL,
    enviado_en timestamp without time zone,
    CONSTRAINT notificaciones_estado_check CHECK (((estado)::text = ANY ((ARRAY['Pendiente'::character varying, 'Enviada'::character varying, 'Fallida'::character varying])::text[])))
);


ALTER TABLE public.notificaciones OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 50387)
-- Name: notificaciones_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notificaciones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notificaciones_id_seq OWNER TO postgres;

--
-- TOC entry 5204 (class 0 OID 0)
-- Dependencies: 251
-- Name: notificaciones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notificaciones_id_seq OWNED BY public.notificaciones.id;


--
-- TOC entry 226 (class 1259 OID 50054)
-- Name: pacientes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pacientes (
    id integer NOT NULL,
    nombre character varying(80) NOT NULL,
    apellido character varying(80) NOT NULL,
    ci character varying(20) NOT NULL,
    fecha_nacimiento date NOT NULL,
    celular character varying(30),
    direccion character varying(180),
    tipo_sangre character varying(5),
    alergias text,
    antecedentes text,
    estado character varying(20) DEFAULT 'Activo'::character varying NOT NULL,
    creado_en timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT pacientes_estado_check CHECK (((estado)::text = ANY ((ARRAY['Activo'::character varying, 'Inactivo'::character varying])::text[]))),
    CONSTRAINT pacientes_tipo_sangre_check CHECK ((((tipo_sangre)::text = ANY ((ARRAY['O+'::character varying, 'O-'::character varying, 'A+'::character varying, 'A-'::character varying, 'B+'::character varying, 'B-'::character varying, 'AB+'::character varying, 'AB-'::character varying])::text[])) OR (tipo_sangre IS NULL)))
);


ALTER TABLE public.pacientes OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 50053)
-- Name: pacientes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pacientes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pacientes_id_seq OWNER TO postgres;

--
-- TOC entry 5205 (class 0 OID 0)
-- Dependencies: 225
-- Name: pacientes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pacientes_id_seq OWNED BY public.pacientes.id;


--
-- TOC entry 242 (class 1259 OID 50268)
-- Name: receta_detalle; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.receta_detalle (
    id integer NOT NULL,
    receta_id integer NOT NULL,
    medicamento_id integer NOT NULL,
    dosis character varying(120),
    frecuencia character varying(120),
    dias integer,
    cantidad integer DEFAULT 1 NOT NULL,
    CONSTRAINT receta_detalle_cantidad_check CHECK ((cantidad >= 1)),
    CONSTRAINT receta_detalle_dias_check CHECK ((dias >= 1))
);


ALTER TABLE public.receta_detalle OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 50267)
-- Name: receta_detalle_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.receta_detalle_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.receta_detalle_id_seq OWNER TO postgres;

--
-- TOC entry 5206 (class 0 OID 0)
-- Dependencies: 241
-- Name: receta_detalle_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.receta_detalle_id_seq OWNED BY public.receta_detalle.id;


--
-- TOC entry 240 (class 1259 OID 50250)
-- Name: recetas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.recetas (
    id integer NOT NULL,
    consulta_id integer NOT NULL,
    indicaciones text,
    fecha timestamp without time zone DEFAULT now() NOT NULL,
    pdf_url text
);


ALTER TABLE public.recetas OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 50249)
-- Name: recetas_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.recetas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.recetas_id_seq OWNER TO postgres;

--
-- TOC entry 5207 (class 0 OID 0)
-- Dependencies: 239
-- Name: recetas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.recetas_id_seq OWNED BY public.recetas.id;


--
-- TOC entry 220 (class 1259 OID 50004)
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    nombre character varying(50) NOT NULL,
    descripcion text
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 50003)
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.roles_id_seq OWNER TO postgres;

--
-- TOC entry 5208 (class 0 OID 0)
-- Dependencies: 219
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- TOC entry 228 (class 1259 OID 50076)
-- Name: usuarios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuarios (
    id integer NOT NULL,
    rol_id integer NOT NULL,
    paciente_id integer,
    medico_id integer,
    nombre character varying(80) NOT NULL,
    apellido character varying(80) NOT NULL,
    correo character varying(120) NOT NULL,
    password_hash character(64) NOT NULL,
    estado character varying(20) DEFAULT 'Activo'::character varying NOT NULL,
    foto_url text,
    creado_en timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT usuarios_estado_check CHECK (((estado)::text = ANY ((ARRAY['Activo'::character varying, 'Inactivo'::character varying])::text[])))
);


ALTER TABLE public.usuarios OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 50075)
-- Name: usuarios_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.usuarios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.usuarios_id_seq OWNER TO postgres;

--
-- TOC entry 5209 (class 0 OID 0)
-- Dependencies: 227
-- Name: usuarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.usuarios_id_seq OWNED BY public.usuarios.id;


--
-- TOC entry 250 (class 1259 OID 50362)
-- Name: venta_detalle; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.venta_detalle (
    id integer NOT NULL,
    venta_id integer NOT NULL,
    medicamento_id integer NOT NULL,
    cantidad integer NOT NULL,
    precio_unitario numeric(10,2) DEFAULT 0 NOT NULL,
    subtotal numeric(10,2) DEFAULT 0 NOT NULL,
    CONSTRAINT venta_detalle_cantidad_check CHECK ((cantidad > 0))
);


ALTER TABLE public.venta_detalle OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 50361)
-- Name: venta_detalle_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.venta_detalle_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.venta_detalle_id_seq OWNER TO postgres;

--
-- TOC entry 5210 (class 0 OID 0)
-- Dependencies: 249
-- Name: venta_detalle_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.venta_detalle_id_seq OWNED BY public.venta_detalle.id;


--
-- TOC entry 248 (class 1259 OID 50338)
-- Name: ventas_farmacia; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ventas_farmacia (
    id integer NOT NULL,
    paciente_id integer,
    usuario_id integer,
    fecha timestamp without time zone DEFAULT now() NOT NULL,
    observacion text,
    total numeric(10,2) DEFAULT 0 NOT NULL
);


ALTER TABLE public.ventas_farmacia OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 50337)
-- Name: ventas_farmacia_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ventas_farmacia_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ventas_farmacia_id_seq OWNER TO postgres;

--
-- TOC entry 5211 (class 0 OID 0)
-- Dependencies: 247
-- Name: ventas_farmacia_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ventas_farmacia_id_seq OWNED BY public.ventas_farmacia.id;


--
-- TOC entry 4883 (class 2604 OID 50449)
-- Name: archivos_clinicos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.archivos_clinicos ALTER COLUMN id SET DEFAULT nextval('public.archivos_clinicos_id_seq'::regclass);


--
-- TOC entry 4852 (class 2604 OID 50158)
-- Name: citas id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.citas ALTER COLUMN id SET DEFAULT nextval('public.citas_id_seq'::regclass);


--
-- TOC entry 4879 (class 2604 OID 50430)
-- Name: cola_mensajes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cola_mensajes ALTER COLUMN id SET DEFAULT nextval('public.cola_mensajes_id_seq'::regclass);


--
-- TOC entry 4857 (class 2604 OID 50223)
-- Name: consultas id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.consultas ALTER COLUMN id SET DEFAULT nextval('public.consultas_id_seq'::regclass);


--
-- TOC entry 4835 (class 2604 OID 50020)
-- Name: especialidades id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.especialidades ALTER COLUMN id SET DEFAULT nextval('public.especialidades_id_seq'::regclass);


--
-- TOC entry 4863 (class 2604 OID 50295)
-- Name: examenes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.examenes ALTER COLUMN id SET DEFAULT nextval('public.examenes_id_seq'::regclass);


--
-- TOC entry 4855 (class 2604 OID 50200)
-- Name: expedientes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expedientes ALTER COLUMN id SET DEFAULT nextval('public.expedientes_id_seq'::regclass);


--
-- TOC entry 4845 (class 2604 OID 50116)
-- Name: horarios_medicos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.horarios_medicos ALTER COLUMN id SET DEFAULT nextval('public.horarios_medicos_id_seq'::regclass);


--
-- TOC entry 4886 (class 2604 OID 50475)
-- Name: logs_actividad id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.logs_actividad ALTER COLUMN id SET DEFAULT nextval('public.logs_actividad_id_seq'::regclass);


--
-- TOC entry 4846 (class 2604 OID 50133)
-- Name: medicamentos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medicamentos ALTER COLUMN id SET DEFAULT nextval('public.medicamentos_id_seq'::regclass);


--
-- TOC entry 4837 (class 2604 OID 50035)
-- Name: medicos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medicos ALTER COLUMN id SET DEFAULT nextval('public.medicos_id_seq'::regclass);


--
-- TOC entry 4865 (class 2604 OID 50314)
-- Name: movimientos_stock id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimientos_stock ALTER COLUMN id SET DEFAULT nextval('public.movimientos_stock_id_seq'::regclass);


--
-- TOC entry 4873 (class 2604 OID 50391)
-- Name: notificaciones id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notificaciones ALTER COLUMN id SET DEFAULT nextval('public.notificaciones_id_seq'::regclass);


--
-- TOC entry 4839 (class 2604 OID 50057)
-- Name: pacientes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pacientes ALTER COLUMN id SET DEFAULT nextval('public.pacientes_id_seq'::regclass);


--
-- TOC entry 4861 (class 2604 OID 50271)
-- Name: receta_detalle id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receta_detalle ALTER COLUMN id SET DEFAULT nextval('public.receta_detalle_id_seq'::regclass);


--
-- TOC entry 4859 (class 2604 OID 50253)
-- Name: recetas id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recetas ALTER COLUMN id SET DEFAULT nextval('public.recetas_id_seq'::regclass);


--
-- TOC entry 4834 (class 2604 OID 50007)
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- TOC entry 4842 (class 2604 OID 50079)
-- Name: usuarios id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios ALTER COLUMN id SET DEFAULT nextval('public.usuarios_id_seq'::regclass);


--
-- TOC entry 4870 (class 2604 OID 50365)
-- Name: venta_detalle id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venta_detalle ALTER COLUMN id SET DEFAULT nextval('public.venta_detalle_id_seq'::regclass);


--
-- TOC entry 4867 (class 2604 OID 50341)
-- Name: ventas_farmacia id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ventas_farmacia ALTER COLUMN id SET DEFAULT nextval('public.ventas_farmacia_id_seq'::regclass);


--
-- TOC entry 5182 (class 0 OID 50446)
-- Dependencies: 256
-- Data for Name: archivos_clinicos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.archivos_clinicos (id, expediente_id, nombre_archivo, tipo_archivo, storage_provider, storage_url, descripcion, subido_por, creado_en) FROM stdin;
1	1	electro-juan-perez.txt	text/plain	Almacenamiento local simulado	/uploads/clinicos/electro-juan-perez.txt	Electrocardiograma adjunto al expediente clínico.	3	2026-06-06 18:47:59.284375
2	3	hemograma-mateo.txt	text/plain	Almacenamiento local simulado	/uploads/clinicos/hemograma-mateo.txt	Resultado de hemograma del paciente pediátrico.	3	2026-06-06 18:47:59.284375
3	5	control-diabetes-carlos.txt	text/plain	Almacenamiento local simulado	/uploads/clinicos/control-diabetes-carlos.txt	Control de glucosa para seguimiento.	3	2026-06-06 18:47:59.284375
\.


--
-- TOC entry 5160 (class 0 OID 50155)
-- Dependencies: 234
-- Data for Name: citas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.citas (id, paciente_id, medico_id, especialidad_id, fecha, hora, motivo, estado, creado_por, creado_en) FROM stdin;
1	1	1	1	2026-06-06	08:30:00	Control de presión arterial	Atendida	2	2026-06-06 18:47:59.284375
2	2	5	5	2026-06-06	09:00:00	Control ginecológico	Confirmada	2	2026-06-06 18:47:59.284375
3	3	2	2	2026-06-06	09:30:00	Tos y fiebre	Atendida	2	2026-06-06 18:47:59.284375
4	4	6	6	2026-06-06	10:00:00	Dolor de cabeza recurrente	Pendiente	2	2026-06-06 18:47:59.284375
5	5	3	3	2026-06-06	10:30:00	Dolor de pecho leve	Confirmada	2	2026-06-06 18:47:59.284375
6	6	1	1	2026-06-07	08:00:00	Dolor estomacal	Pendiente	2	2026-06-06 18:47:59.284375
7	7	4	4	2026-06-07	08:30:00	Dolor de rodilla	Pendiente	2	2026-06-06 18:47:59.284375
8	8	2	2	2026-06-07	09:00:00	Control pediátrico	Pendiente	2	2026-06-06 18:47:59.284375
9	9	3	3	2026-06-05	11:00:00	Control cardiológico	Atendida	2	2026-06-06 18:47:59.284375
10	10	1	1	2026-06-05	11:30:00	Revisión general	Cancelada	2	2026-06-06 18:47:59.284375
11	1	3	3	2026-06-04	09:00:00	Electrocardiograma	Atendida	2	2026-06-06 18:47:59.284375
12	3	2	2	2026-06-04	10:30:00	Control por asma	Atendida	2	2026-06-06 18:47:59.284375
\.


--
-- TOC entry 5180 (class 0 OID 50427)
-- Dependencies: 254
-- Data for Name: cola_mensajes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cola_mensajes (id, tipo, referencia_id, payload, estado, intentos, creado_en, procesado_en) FROM stdin;
1	RECORDATORIO_CITA	5	{"hora": "10:00", "fecha": "hoy", "paciente": "Valeria Condori", "especialidad": "Neurología"}	Pendiente	0	2026-06-06 18:37:59.284375	\N
2	REPORTE_DIARIO	\N	{"tipo": "dashboard gerencial", "fecha": "hoy"}	Procesado	1	2026-06-06 16:47:59.284375	2026-06-06 16:47:59.284375
\.


--
-- TOC entry 5164 (class 0 OID 50220)
-- Dependencies: 238
-- Data for Name: consultas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.consultas (id, expediente_id, cita_id, medico_id, fecha, diagnostico, tratamiento, observaciones) FROM stdin;
1	1	1	1	2026-06-06 16:47:59.284375	Hipertensión arterial controlada	Continuar con control de presión y dieta baja en sal.	Se agenda seguimiento mensual.
2	3	3	2	2026-06-06 17:47:59.284375	Infección respiratoria alta	Reposo, hidratación y control de temperatura.	Paciente estable.
3	9	9	3	2026-06-05 18:47:59.284375	Hipertensión con control irregular	Ajustar medicación y seguimiento cardiológico.	Se recomienda control en 15 días.
4	1	11	3	2026-06-04 18:47:59.284375	Evaluación cardiológica preventiva	Electrocardiograma y control general.	Resultado sin alteraciones graves.
5	3	12	2	2026-06-04 18:47:59.284375	Asma leve en control	Uso de inhalador según necesidad.	Explicar signos de alarma.
\.


--
-- TOC entry 5148 (class 0 OID 50017)
-- Dependencies: 222
-- Data for Name: especialidades; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.especialidades (id, nombre, descripcion, estado) FROM stdin;
1	Medicina General	Atención médica primaria y diagnóstico inicial.	Activo
2	Pediatría	Atención médica para niños y adolescentes.	Activo
3	Cardiología	Control y tratamiento de enfermedades del corazón.	Activo
4	Traumatología	Lesiones óseas, articulares y musculares.	Activo
5	Ginecología	Atención médica integral para la salud femenina.	Activo
6	Neurología	Diagnóstico y tratamiento del sistema nervioso.	Activo
\.


--
-- TOC entry 5170 (class 0 OID 50292)
-- Dependencies: 244
-- Data for Name: examenes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.examenes (id, consulta_id, tipo, descripcion, resultado, archivo_url, fecha) FROM stdin;
1	4	Electrocardiograma	Control preventivo solicitado por cardiología.	Ritmo sinusal, sin signos de alarma.	/uploads/clinicos/electro-juan-perez.txt	2026-06-06 18:47:59.284375
2	2	Hemograma	Solicitado por fiebre persistente.	Leucocitos levemente elevados.	/uploads/clinicos/hemograma-mateo.txt	2026-06-06 18:47:59.284375
\.


--
-- TOC entry 5162 (class 0 OID 50197)
-- Dependencies: 236
-- Data for Name: expedientes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.expedientes (id, paciente_id, codigo, observaciones_generales, creado_en) FROM stdin;
1	1	EXP-2026-0001	Expediente clínico digital creado para seguimiento.	2026-06-06 18:47:59.284375
2	2	EXP-2026-0002	Expediente clínico digital creado para seguimiento.	2026-06-06 18:47:59.284375
3	3	EXP-2026-0003	Expediente clínico digital creado para seguimiento.	2026-06-06 18:47:59.284375
4	4	EXP-2026-0004	Expediente clínico digital creado para seguimiento.	2026-06-06 18:47:59.284375
5	5	EXP-2026-0005	Expediente clínico digital creado para seguimiento.	2026-06-06 18:47:59.284375
6	6	EXP-2026-0006	Expediente clínico digital creado para seguimiento.	2026-06-06 18:47:59.284375
7	7	EXP-2026-0007	Expediente clínico digital creado para seguimiento.	2026-06-06 18:47:59.284375
8	8	EXP-2026-0008	Expediente clínico digital creado para seguimiento.	2026-06-06 18:47:59.284375
9	9	EXP-2026-0009	Expediente clínico digital creado para seguimiento.	2026-06-06 18:47:59.284375
10	10	EXP-2026-0010	Expediente clínico digital creado para seguimiento.	2026-06-06 18:47:59.284375
\.


--
-- TOC entry 5156 (class 0 OID 50113)
-- Dependencies: 230
-- Data for Name: horarios_medicos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.horarios_medicos (id, medico_id, dia_semana, hora_inicio, hora_fin, consultorio) FROM stdin;
1	1	Lunes	08:00:00	12:00:00	C-101
2	1	Miércoles	14:00:00	18:00:00	C-101
3	1	Sábado	08:00:00	12:00:00	C-101
4	2	Martes	08:00:00	12:00:00	P-203
5	2	Jueves	08:00:00	12:00:00	P-203
6	2	Sábado	09:00:00	12:00:00	P-203
7	3	Lunes	14:00:00	18:00:00	CA-305
8	3	Viernes	08:00:00	12:00:00	CA-305
9	3	Sábado	10:00:00	13:00:00	CA-305
10	4	Miércoles	08:00:00	12:00:00	T-110
11	4	Sábado	08:00:00	11:00:00	T-110
12	5	Martes	14:00:00	18:00:00	G-212
13	5	Jueves	14:00:00	18:00:00	G-212
14	6	Jueves	14:00:00	18:00:00	N-410
\.


--
-- TOC entry 5184 (class 0 OID 50472)
-- Dependencies: 258
-- Data for Name: logs_actividad; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.logs_actividad (id, usuario_id, modulo, accion, detalle, creado_en) FROM stdin;
1	2	Pacientes	Registro	Se registraron datos de paciente nuevo.	2026-06-06 13:47:59.284375
2	2	Citas	Agenda	Se agendó cita médica para Medicina General.	2026-06-06 14:47:59.284375
3	3	Expediente clínico	Consulta	Se registró diagnóstico y tratamiento.	2026-06-06 15:47:59.284375
4	4	Farmacia	Venta	Se registró una venta de medicamentos por receta.	2026-06-06 16:47:59.284375
5	1	Dashboard	Revisión	Se revisaron indicadores gerenciales del día.	2026-06-06 17:47:59.284375
6	4	Farmacia	Solicitud de revisión	Farmacia reportó una diferencia de stock para revisión del administrador.	2026-06-06 18:12:59.284375
7	1	Perfil	Actualización	El usuario actualizó su perfil.	2026-06-06 18:55:23.126481
8	1	Perfil	Actualización	El usuario actualizó su perfil.	2026-06-06 18:55:25.995035
9	1	Pacientes	Cambio de estado	Paciente Camila Mendoza ahora está Activo.	2026-06-06 18:56:51.814517
10	1	Pacientes	Cambio de estado	Paciente Camila Mendoza ahora está Inactivo.	2026-06-06 18:56:53.189176
11	4	Farmacia	Venta	Se registró venta de farmacia por Bs 3.50.	2026-06-06 20:34:42.256269
\.


--
-- TOC entry 5158 (class 0 OID 50130)
-- Dependencies: 232
-- Data for Name: medicamentos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.medicamentos (id, codigo, nombre, presentacion, concentracion, categoria, precio, stock, stock_minimo, fecha_vencimiento, estado, actualizado_en) FROM stdin;
1	MED-001	Paracetamol	Tabletas	500 mg	Analgésico	1.50	85	20	2027-01-20	Disponible	2026-06-06 18:47:59.284375
2	MED-002	Ibuprofeno	Tabletas	400 mg	Antiinflamatorio	2.00	18	20	2026-09-15	Bajo stock	2026-06-06 18:47:59.284375
4	MED-004	Omeprazol	Cápsulas	20 mg	Gastroprotector	1.80	9	15	2026-08-30	Bajo stock	2026-06-06 18:47:59.284375
5	MED-005	Loratadina	Tabletas	10 mg	Antialérgico	1.20	36	10	2027-04-12	Disponible	2026-06-06 18:47:59.284375
6	MED-006	Salbutamol	Inhalador	100 mcg	Respiratorio	45.00	6	8	2026-07-05	Bajo stock	2026-06-06 18:47:59.284375
7	MED-007	Metformina	Tabletas	850 mg	Antidiabético	2.20	52	20	2027-02-14	Disponible	2026-06-06 18:47:59.284375
8	MED-008	Losartán	Tabletas	50 mg	Antihipertensivo	2.50	13	18	2026-10-28	Bajo stock	2026-06-06 18:47:59.284375
9	MED-009	Diclofenaco	Ampollas	75 mg	Antiinflamatorio	8.00	0	10	2026-12-12	Agotado	2026-06-06 18:47:59.284375
10	MED-010	Suero fisiológico	Bolsa	1000 ml	Solución	12.00	67	25	2027-06-01	Disponible	2026-06-06 18:47:59.284375
11	MED-011	Azitromicina	Suspensión	200 mg/5 ml	Antibiótico	38.00	15	8	2027-02-20	Disponible	2026-06-06 18:47:59.284375
12	MED-012	Ambroxol	Jarabe	15 mg/5 ml	Respiratorio	22.00	11	10	2026-12-18	Disponible	2026-06-06 18:47:59.284375
3	MED-003	Amoxicilina	Cápsulas	500 mg	Antibiótico	3.50	43	15	2027-03-02	Disponible	2026-06-06 20:34:42.12876
\.


--
-- TOC entry 5150 (class 0 OID 50032)
-- Dependencies: 224
-- Data for Name: medicos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.medicos (id, especialidad_id, nombre, apellido, ci, correo, telefono, nro_matricula, estado) FROM stdin;
1	1	Rodrigo	Mamani	4567891	rodrigo.mamani@mediclinic.bo	70651234	MC-1001	Disponible
2	2	Andrea	Vargas	4988123	andrea.vargas@mediclinic.bo	71547890	MC-1002	Disponible
3	3	Luis	Arce	5214769	luis.arce@mediclinic.bo	72014563	MC-1003	Disponible
4	4	Paola	Rojas	6123450	paola.rojas@mediclinic.bo	70124587	MC-1004	Disponible
5	5	Carla	Salazar	6321478	carla.salazar@mediclinic.bo	69874512	MC-1005	Disponible
6	6	Javier	Paredes	6987451	javier.paredes@mediclinic.bo	73450198	MC-1006	No disponible
\.


--
-- TOC entry 5172 (class 0 OID 50311)
-- Dependencies: 246
-- Data for Name: movimientos_stock; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.movimientos_stock (id, medicamento_id, tipo, cantidad, motivo, usuario_id, creado_en) FROM stdin;
1	1	Salida	9	Receta por infección respiratoria	4	2026-06-06 16:47:59.284375
2	5	Salida	5	Receta por alergia respiratoria	4	2026-06-06 16:47:59.284375
3	8	Salida	30	Tratamiento hipertensión	4	2026-06-06 17:47:59.284375
4	6	Salida	1	Control por asma leve	4	2026-06-04 18:47:59.284375
5	10	Entrada	25	Reposición semanal de farmacia	4	2026-06-05 18:47:59.284375
6	3	Salida	1	Venta registrada #4	4	2026-06-06 20:34:42.192981
\.


--
-- TOC entry 5178 (class 0 OID 50388)
-- Dependencies: 252
-- Data for Name: notificaciones; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notificaciones (id, usuario_destino_id, paciente_id, cita_id, destinatario, asunto, mensaje, canal, estado, tipo, leida, creado_en, enviado_en) FROM stdin;
1	5	1	1	Juan Pérez	Recordatorio de cita médica	Recuerde su cita de Medicina General de hoy a horas 08:30.	Sistema interno	Enviada	RECORDATORIO_CITA	f	2026-06-06 17:47:59.284375	2026-06-06 17:47:59.284375
2	6	2	2	Lucía Fernández	Recordatorio de cita médica	Recuerde su cita de Ginecología de hoy a horas 09:00.	Sistema interno	Enviada	RECORDATORIO_CITA	t	2026-06-06 16:47:59.284375	2026-06-06 16:47:59.284375
3	4	1	\N	Farmacia	Nueva receta médica	Tiene una receta pendiente para Juan Pérez. Revise los medicamentos solicitados.	Sistema interno	Enviada	RECETA_FARMACIA	f	2026-06-06 18:12:59.284375	2026-06-06 18:12:59.284375
4	1	\N	\N	Administrador	Stock crítico en farmacia	Existen medicamentos con bajo stock o agotados que requieren revisión.	Sistema interno	Enviada	SISTEMA	t	2026-06-06 18:22:59.284375	2026-06-06 18:22:59.284375
5	2	4	4	Valeria Condori	Recordatorio de cita médica	Recordatorio pendiente generado por cola de mensajes.	Correo simulado	Pendiente	RECORDATORIO_CITA	t	2026-06-06 18:37:59.284375	\N
\.


--
-- TOC entry 5152 (class 0 OID 50054)
-- Dependencies: 226
-- Data for Name: pacientes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pacientes (id, nombre, apellido, ci, fecha_nacimiento, celular, direccion, tipo_sangre, alergias, antecedentes, estado, creado_en) FROM stdin;
1	Juan	Pérez	7894561	1988-03-12	76543210	Miraflores, La Paz	O+	Ninguna	Hipertensión controlada	Activo	2026-06-06 18:47:59.284375
2	Lucía	Fernández	7012458	1996-11-04	71234567	Villa Fátima, La Paz	A+	Penicilina	Sin antecedentes relevantes	Activo	2026-06-06 18:47:59.284375
3	Mateo	Gutiérrez	8123490	2018-07-22	72561478	Sopocachi, La Paz	B+	Ninguna	Asma leve	Activo	2026-06-06 18:47:59.284375
4	Valeria	Condori	6541239	2001-01-15	70123698	Alto Obrajes, La Paz	O-	Ibuprofeno	Migrañas ocasionales	Activo	2026-06-06 18:47:59.284375
5	Carlos	Ramos	5487963	1979-09-09	77784512	San Pedro, La Paz	AB+	Ninguna	Diabetes tipo II	Activo	2026-06-06 18:47:59.284375
6	Elena	Flores	4987652	1990-05-28	69874512	Zona Sur, La Paz	A-	Lácteos	Anemia previa	Activo	2026-06-06 18:47:59.284375
7	Diego	Torrez	7236981	1984-12-03	73458912	Achumani, La Paz	O+	Ninguna	Operación de rodilla	Activo	2026-06-06 18:47:59.284375
8	Micaela	Soria	8021456	2012-02-18	71987456	El Tejar, La Paz	B-	Polvo	Rinitis alérgica	Activo	2026-06-06 18:47:59.284375
9	Hugo	Apaza	4178520	1968-08-30	70698541	Munaypata, La Paz	O+	Ninguna	Presión alta	Activo	2026-06-06 18:47:59.284375
10	Camila	Mendoza	8012365	1998-06-10	71596321	Calacoto, La Paz	A+	Ninguna	Sin antecedentes	Inactivo	2026-06-06 18:47:59.284375
\.


--
-- TOC entry 5168 (class 0 OID 50268)
-- Dependencies: 242
-- Data for Name: receta_detalle; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.receta_detalle (id, receta_id, medicamento_id, dosis, frecuencia, dias, cantidad) FROM stdin;
1	1	8	1 tableta	Cada 24 horas	30	30
2	2	1	1 tableta	Cada 8 horas si hay fiebre	3	9
3	2	5	1 tableta	Cada 24 horas	5	5
4	3	8	1 tableta	Cada 24 horas	30	30
5	4	6	2 inhalaciones	Según crisis respiratoria	7	1
\.


--
-- TOC entry 5166 (class 0 OID 50250)
-- Dependencies: 240
-- Data for Name: recetas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.recetas (id, consulta_id, indicaciones, fecha, pdf_url) FROM stdin;
1	1	Tomar medicamento según indicación médica. Evitar automedicación.	2026-06-06 18:47:59.284375	/uploads/clinicos/receta-demo-0001.txt
2	2	Tomar paracetamol solo si hay fiebre mayor a 38°C.	2026-06-06 18:47:59.284375	/uploads/clinicos/receta-demo-0002.txt
3	3	Mantener tratamiento y registrar presión arterial diaria.	2026-06-06 18:47:59.284375	/uploads/clinicos/receta-demo-0003.txt
4	5	Usar inhalador según indicación, no exceder dosis.	2026-06-06 18:47:59.284375	/uploads/clinicos/receta-demo-0004.txt
\.


--
-- TOC entry 5146 (class 0 OID 50004)
-- Dependencies: 220
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (id, nombre, descripcion) FROM stdin;
1	Administrador	Gestiona usuarios, reportes y configuración general.
2	Recepcion	Registra pacientes y agenda citas médicas.
3	Medico	Atiende pacientes y actualiza expedientes clínicos.
4	Farmacia	Administra medicamentos, ventas y stock.
5	Paciente	Consulta sus citas, notificaciones y expediente clínico.
\.


--
-- TOC entry 5154 (class 0 OID 50076)
-- Dependencies: 228
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.usuarios (id, rol_id, paciente_id, medico_id, nombre, apellido, correo, password_hash, estado, foto_url, creado_en) FROM stdin;
2	2	\N	\N	Daniel	Choque	recepcion@mediclinic.bo	e7af7bf39dbc423a5e12298ae05f86bb3b227d8b9d7c3656b9990ffeb0015219	Activo	\N	2026-06-06 18:47:59.284375
3	3	\N	1	Rodrigo	Mamani	doctor@mediclinic.bo	f348d5628621f3d8f59c8cabda0f8eb0aa7e0514a90be7571020b1336f26c113	Activo	\N	2026-06-06 18:47:59.284375
4	4	\N	\N	María	Quispe	farmacia@mediclinic.bo	70ff717b7ed9b950b13e47c61b844ae895ff3c6ed822a2d0b967110dec29aa5f	Activo	\N	2026-06-06 18:47:59.284375
5	5	1	\N	Juan	Pérez	juan.perez@paciente.bo	299fbb455c42239c86d2ee3b15403ed1b468259ecaedf0c3527451e1f0d63d59	Activo	\N	2026-06-06 18:47:59.284375
6	5	2	\N	Lucía	Fernández	lucia.fernandez@paciente.bo	299fbb455c42239c86d2ee3b15403ed1b468259ecaedf0c3527451e1f0d63d59	Activo	\N	2026-06-06 18:47:59.284375
1	1	\N	\N	Sofía	Calani	admin@mediclinic.bo	240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9	Activo	/uploads/perfiles/perfil_1_1780786525.jpg	2026-06-06 18:47:59.284375
\.


--
-- TOC entry 5176 (class 0 OID 50362)
-- Dependencies: 250
-- Data for Name: venta_detalle; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.venta_detalle (id, venta_id, medicamento_id, cantidad, precio_unitario, subtotal) FROM stdin;
1	1	8	30	2.50	75.00
2	2	1	9	1.50	13.50
3	2	5	4	1.20	4.80
4	3	7	20	2.20	44.00
5	4	3	1	3.50	3.50
\.


--
-- TOC entry 5174 (class 0 OID 50338)
-- Dependencies: 248
-- Data for Name: ventas_farmacia; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ventas_farmacia (id, paciente_id, usuario_id, fecha, observacion, total) FROM stdin;
1	1	4	2026-06-06 17:47:59.284375	Venta por receta de hipertensión.	75.00
2	3	4	2026-06-06 16:47:59.284375	Venta por receta pediátrica.	18.30
3	5	4	2026-06-05 18:47:59.284375	Medicamentos para control de diabetes.	44.00
4	\N	4	2026-06-06 20:34:41.899097		3.50
\.


--
-- TOC entry 5212 (class 0 OID 0)
-- Dependencies: 255
-- Name: archivos_clinicos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.archivos_clinicos_id_seq', 3, true);


--
-- TOC entry 5213 (class 0 OID 0)
-- Dependencies: 233
-- Name: citas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.citas_id_seq', 12, true);


--
-- TOC entry 5214 (class 0 OID 0)
-- Dependencies: 253
-- Name: cola_mensajes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cola_mensajes_id_seq', 2, true);


--
-- TOC entry 5215 (class 0 OID 0)
-- Dependencies: 237
-- Name: consultas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.consultas_id_seq', 5, true);


--
-- TOC entry 5216 (class 0 OID 0)
-- Dependencies: 221
-- Name: especialidades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.especialidades_id_seq', 6, true);


--
-- TOC entry 5217 (class 0 OID 0)
-- Dependencies: 243
-- Name: examenes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.examenes_id_seq', 2, true);


--
-- TOC entry 5218 (class 0 OID 0)
-- Dependencies: 235
-- Name: expedientes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.expedientes_id_seq', 10, true);


--
-- TOC entry 5219 (class 0 OID 0)
-- Dependencies: 229
-- Name: horarios_medicos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.horarios_medicos_id_seq', 14, true);


--
-- TOC entry 5220 (class 0 OID 0)
-- Dependencies: 257
-- Name: logs_actividad_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.logs_actividad_id_seq', 11, true);


--
-- TOC entry 5221 (class 0 OID 0)
-- Dependencies: 231
-- Name: medicamentos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.medicamentos_id_seq', 12, true);


--
-- TOC entry 5222 (class 0 OID 0)
-- Dependencies: 223
-- Name: medicos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.medicos_id_seq', 6, true);


--
-- TOC entry 5223 (class 0 OID 0)
-- Dependencies: 245
-- Name: movimientos_stock_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.movimientos_stock_id_seq', 6, true);


--
-- TOC entry 5224 (class 0 OID 0)
-- Dependencies: 251
-- Name: notificaciones_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notificaciones_id_seq', 5, true);


--
-- TOC entry 5225 (class 0 OID 0)
-- Dependencies: 225
-- Name: pacientes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pacientes_id_seq', 10, true);


--
-- TOC entry 5226 (class 0 OID 0)
-- Dependencies: 241
-- Name: receta_detalle_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.receta_detalle_id_seq', 5, true);


--
-- TOC entry 5227 (class 0 OID 0)
-- Dependencies: 239
-- Name: recetas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.recetas_id_seq', 4, true);


--
-- TOC entry 5228 (class 0 OID 0)
-- Dependencies: 219
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.roles_id_seq', 5, true);


--
-- TOC entry 5229 (class 0 OID 0)
-- Dependencies: 227
-- Name: usuarios_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.usuarios_id_seq', 6, true);


--
-- TOC entry 5230 (class 0 OID 0)
-- Dependencies: 249
-- Name: venta_detalle_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.venta_detalle_id_seq', 5, true);


--
-- TOC entry 5231 (class 0 OID 0)
-- Dependencies: 247
-- Name: ventas_farmacia_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ventas_farmacia_id_seq', 4, true);


--
-- TOC entry 4966 (class 2606 OID 50460)
-- Name: archivos_clinicos archivos_clinicos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.archivos_clinicos
    ADD CONSTRAINT archivos_clinicos_pkey PRIMARY KEY (id);


--
-- TOC entry 4933 (class 2606 OID 50175)
-- Name: citas citas_medico_id_fecha_hora_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.citas
    ADD CONSTRAINT citas_medico_id_fecha_hora_key UNIQUE (medico_id, fecha, hora);


--
-- TOC entry 4935 (class 2606 OID 50173)
-- Name: citas citas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.citas
    ADD CONSTRAINT citas_pkey PRIMARY KEY (id);


--
-- TOC entry 4964 (class 2606 OID 50444)
-- Name: cola_mensajes cola_mensajes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cola_mensajes
    ADD CONSTRAINT cola_mensajes_pkey PRIMARY KEY (id);


--
-- TOC entry 4945 (class 2606 OID 50233)
-- Name: consultas consultas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.consultas
    ADD CONSTRAINT consultas_pkey PRIMARY KEY (id);


--
-- TOC entry 4909 (class 2606 OID 50030)
-- Name: especialidades especialidades_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.especialidades
    ADD CONSTRAINT especialidades_nombre_key UNIQUE (nombre);


--
-- TOC entry 4911 (class 2606 OID 50028)
-- Name: especialidades especialidades_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.especialidades
    ADD CONSTRAINT especialidades_pkey PRIMARY KEY (id);


--
-- TOC entry 4951 (class 2606 OID 50304)
-- Name: examenes examenes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.examenes
    ADD CONSTRAINT examenes_pkey PRIMARY KEY (id);


--
-- TOC entry 4939 (class 2606 OID 50213)
-- Name: expedientes expedientes_codigo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expedientes
    ADD CONSTRAINT expedientes_codigo_key UNIQUE (codigo);


--
-- TOC entry 4941 (class 2606 OID 50211)
-- Name: expedientes expedientes_paciente_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expedientes
    ADD CONSTRAINT expedientes_paciente_id_key UNIQUE (paciente_id);


--
-- TOC entry 4943 (class 2606 OID 50209)
-- Name: expedientes expedientes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expedientes
    ADD CONSTRAINT expedientes_pkey PRIMARY KEY (id);


--
-- TOC entry 4926 (class 2606 OID 50123)
-- Name: horarios_medicos horarios_medicos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.horarios_medicos
    ADD CONSTRAINT horarios_medicos_pkey PRIMARY KEY (id);


--
-- TOC entry 4968 (class 2606 OID 50484)
-- Name: logs_actividad logs_actividad_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.logs_actividad
    ADD CONSTRAINT logs_actividad_pkey PRIMARY KEY (id);


--
-- TOC entry 4929 (class 2606 OID 50153)
-- Name: medicamentos medicamentos_codigo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medicamentos
    ADD CONSTRAINT medicamentos_codigo_key UNIQUE (codigo);


--
-- TOC entry 4931 (class 2606 OID 50151)
-- Name: medicamentos medicamentos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medicamentos
    ADD CONSTRAINT medicamentos_pkey PRIMARY KEY (id);


--
-- TOC entry 4913 (class 2606 OID 50047)
-- Name: medicos medicos_ci_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medicos
    ADD CONSTRAINT medicos_ci_key UNIQUE (ci);


--
-- TOC entry 4915 (class 2606 OID 50045)
-- Name: medicos medicos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medicos
    ADD CONSTRAINT medicos_pkey PRIMARY KEY (id);


--
-- TOC entry 4953 (class 2606 OID 50326)
-- Name: movimientos_stock movimientos_stock_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimientos_stock
    ADD CONSTRAINT movimientos_stock_pkey PRIMARY KEY (id);


--
-- TOC entry 4962 (class 2606 OID 50410)
-- Name: notificaciones notificaciones_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notificaciones
    ADD CONSTRAINT notificaciones_pkey PRIMARY KEY (id);


--
-- TOC entry 4918 (class 2606 OID 50074)
-- Name: pacientes pacientes_ci_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pacientes
    ADD CONSTRAINT pacientes_ci_key UNIQUE (ci);


--
-- TOC entry 4920 (class 2606 OID 50072)
-- Name: pacientes pacientes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pacientes
    ADD CONSTRAINT pacientes_pkey PRIMARY KEY (id);


--
-- TOC entry 4949 (class 2606 OID 50280)
-- Name: receta_detalle receta_detalle_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receta_detalle
    ADD CONSTRAINT receta_detalle_pkey PRIMARY KEY (id);


--
-- TOC entry 4947 (class 2606 OID 50261)
-- Name: recetas recetas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recetas
    ADD CONSTRAINT recetas_pkey PRIMARY KEY (id);


--
-- TOC entry 4905 (class 2606 OID 50015)
-- Name: roles roles_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_nombre_key UNIQUE (nombre);


--
-- TOC entry 4907 (class 2606 OID 50013)
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- TOC entry 4922 (class 2606 OID 50096)
-- Name: usuarios usuarios_correo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_correo_key UNIQUE (correo);


--
-- TOC entry 4924 (class 2606 OID 50094)
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);


--
-- TOC entry 4958 (class 2606 OID 50376)
-- Name: venta_detalle venta_detalle_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venta_detalle
    ADD CONSTRAINT venta_detalle_pkey PRIMARY KEY (id);


--
-- TOC entry 4956 (class 2606 OID 50350)
-- Name: ventas_farmacia ventas_farmacia_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ventas_farmacia
    ADD CONSTRAINT ventas_farmacia_pkey PRIMARY KEY (id);


--
-- TOC entry 4936 (class 1259 OID 50491)
-- Name: idx_citas_estado; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_citas_estado ON public.citas USING btree (estado);


--
-- TOC entry 4937 (class 1259 OID 50490)
-- Name: idx_citas_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_citas_fecha ON public.citas USING btree (fecha);


--
-- TOC entry 4927 (class 1259 OID 50493)
-- Name: idx_medicamentos_stock; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_medicamentos_stock ON public.medicamentos USING btree (stock);


--
-- TOC entry 4959 (class 1259 OID 50494)
-- Name: idx_notificaciones_estado; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notificaciones_estado ON public.notificaciones USING btree (estado);


--
-- TOC entry 4960 (class 1259 OID 50495)
-- Name: idx_notificaciones_leida; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notificaciones_leida ON public.notificaciones USING btree (leida);


--
-- TOC entry 4916 (class 1259 OID 50492)
-- Name: idx_pacientes_ci; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pacientes_ci ON public.pacientes USING btree (ci);


--
-- TOC entry 4954 (class 1259 OID 50496)
-- Name: idx_ventas_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ventas_fecha ON public.ventas_farmacia USING btree (fecha);


--
-- TOC entry 4995 (class 2606 OID 50461)
-- Name: archivos_clinicos archivos_clinicos_expediente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.archivos_clinicos
    ADD CONSTRAINT archivos_clinicos_expediente_id_fkey FOREIGN KEY (expediente_id) REFERENCES public.expedientes(id);


--
-- TOC entry 4996 (class 2606 OID 50466)
-- Name: archivos_clinicos archivos_clinicos_subido_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.archivos_clinicos
    ADD CONSTRAINT archivos_clinicos_subido_por_fkey FOREIGN KEY (subido_por) REFERENCES public.usuarios(id);


--
-- TOC entry 4974 (class 2606 OID 50191)
-- Name: citas citas_creado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.citas
    ADD CONSTRAINT citas_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.usuarios(id);


--
-- TOC entry 4975 (class 2606 OID 50186)
-- Name: citas citas_especialidad_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.citas
    ADD CONSTRAINT citas_especialidad_id_fkey FOREIGN KEY (especialidad_id) REFERENCES public.especialidades(id);


--
-- TOC entry 4976 (class 2606 OID 50181)
-- Name: citas citas_medico_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.citas
    ADD CONSTRAINT citas_medico_id_fkey FOREIGN KEY (medico_id) REFERENCES public.medicos(id);


--
-- TOC entry 4977 (class 2606 OID 50176)
-- Name: citas citas_paciente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.citas
    ADD CONSTRAINT citas_paciente_id_fkey FOREIGN KEY (paciente_id) REFERENCES public.pacientes(id);


--
-- TOC entry 4979 (class 2606 OID 50239)
-- Name: consultas consultas_cita_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.consultas
    ADD CONSTRAINT consultas_cita_id_fkey FOREIGN KEY (cita_id) REFERENCES public.citas(id);


--
-- TOC entry 4980 (class 2606 OID 50234)
-- Name: consultas consultas_expediente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.consultas
    ADD CONSTRAINT consultas_expediente_id_fkey FOREIGN KEY (expediente_id) REFERENCES public.expedientes(id);


--
-- TOC entry 4981 (class 2606 OID 50244)
-- Name: consultas consultas_medico_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.consultas
    ADD CONSTRAINT consultas_medico_id_fkey FOREIGN KEY (medico_id) REFERENCES public.medicos(id);


--
-- TOC entry 4985 (class 2606 OID 50305)
-- Name: examenes examenes_consulta_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.examenes
    ADD CONSTRAINT examenes_consulta_id_fkey FOREIGN KEY (consulta_id) REFERENCES public.consultas(id);


--
-- TOC entry 4978 (class 2606 OID 50214)
-- Name: expedientes expedientes_paciente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expedientes
    ADD CONSTRAINT expedientes_paciente_id_fkey FOREIGN KEY (paciente_id) REFERENCES public.pacientes(id);


--
-- TOC entry 4973 (class 2606 OID 50124)
-- Name: horarios_medicos horarios_medicos_medico_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.horarios_medicos
    ADD CONSTRAINT horarios_medicos_medico_id_fkey FOREIGN KEY (medico_id) REFERENCES public.medicos(id);


--
-- TOC entry 4997 (class 2606 OID 50485)
-- Name: logs_actividad logs_actividad_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.logs_actividad
    ADD CONSTRAINT logs_actividad_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- TOC entry 4969 (class 2606 OID 50048)
-- Name: medicos medicos_especialidad_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medicos
    ADD CONSTRAINT medicos_especialidad_id_fkey FOREIGN KEY (especialidad_id) REFERENCES public.especialidades(id);


--
-- TOC entry 4986 (class 2606 OID 50327)
-- Name: movimientos_stock movimientos_stock_medicamento_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimientos_stock
    ADD CONSTRAINT movimientos_stock_medicamento_id_fkey FOREIGN KEY (medicamento_id) REFERENCES public.medicamentos(id);


--
-- TOC entry 4987 (class 2606 OID 50332)
-- Name: movimientos_stock movimientos_stock_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimientos_stock
    ADD CONSTRAINT movimientos_stock_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- TOC entry 4992 (class 2606 OID 50421)
-- Name: notificaciones notificaciones_cita_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notificaciones
    ADD CONSTRAINT notificaciones_cita_id_fkey FOREIGN KEY (cita_id) REFERENCES public.citas(id);


--
-- TOC entry 4993 (class 2606 OID 50416)
-- Name: notificaciones notificaciones_paciente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notificaciones
    ADD CONSTRAINT notificaciones_paciente_id_fkey FOREIGN KEY (paciente_id) REFERENCES public.pacientes(id);


--
-- TOC entry 4994 (class 2606 OID 50411)
-- Name: notificaciones notificaciones_usuario_destino_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notificaciones
    ADD CONSTRAINT notificaciones_usuario_destino_id_fkey FOREIGN KEY (usuario_destino_id) REFERENCES public.usuarios(id);


--
-- TOC entry 4983 (class 2606 OID 50286)
-- Name: receta_detalle receta_detalle_medicamento_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receta_detalle
    ADD CONSTRAINT receta_detalle_medicamento_id_fkey FOREIGN KEY (medicamento_id) REFERENCES public.medicamentos(id);


--
-- TOC entry 4984 (class 2606 OID 50281)
-- Name: receta_detalle receta_detalle_receta_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receta_detalle
    ADD CONSTRAINT receta_detalle_receta_id_fkey FOREIGN KEY (receta_id) REFERENCES public.recetas(id);


--
-- TOC entry 4982 (class 2606 OID 50262)
-- Name: recetas recetas_consulta_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recetas
    ADD CONSTRAINT recetas_consulta_id_fkey FOREIGN KEY (consulta_id) REFERENCES public.consultas(id);


--
-- TOC entry 4970 (class 2606 OID 50107)
-- Name: usuarios usuarios_medico_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_medico_id_fkey FOREIGN KEY (medico_id) REFERENCES public.medicos(id);


--
-- TOC entry 4971 (class 2606 OID 50102)
-- Name: usuarios usuarios_paciente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_paciente_id_fkey FOREIGN KEY (paciente_id) REFERENCES public.pacientes(id);


--
-- TOC entry 4972 (class 2606 OID 50097)
-- Name: usuarios usuarios_rol_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES public.roles(id);


--
-- TOC entry 4990 (class 2606 OID 50382)
-- Name: venta_detalle venta_detalle_medicamento_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venta_detalle
    ADD CONSTRAINT venta_detalle_medicamento_id_fkey FOREIGN KEY (medicamento_id) REFERENCES public.medicamentos(id);


--
-- TOC entry 4991 (class 2606 OID 50377)
-- Name: venta_detalle venta_detalle_venta_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venta_detalle
    ADD CONSTRAINT venta_detalle_venta_id_fkey FOREIGN KEY (venta_id) REFERENCES public.ventas_farmacia(id);


--
-- TOC entry 4988 (class 2606 OID 50351)
-- Name: ventas_farmacia ventas_farmacia_paciente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ventas_farmacia
    ADD CONSTRAINT ventas_farmacia_paciente_id_fkey FOREIGN KEY (paciente_id) REFERENCES public.pacientes(id);


--
-- TOC entry 4989 (class 2606 OID 50356)
-- Name: ventas_farmacia ventas_farmacia_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ventas_farmacia
    ADD CONSTRAINT ventas_farmacia_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- TOC entry 5191 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;


-- Completed on 2026-06-06 22:49:42

--
-- PostgreSQL database dump complete
--

\unrestrict yx3c2lcuxLjfnkbsBRuN9xWvIQQQ2F3g7K2clUV2h9G1PmE4TLfd4SfdtVp14lh

