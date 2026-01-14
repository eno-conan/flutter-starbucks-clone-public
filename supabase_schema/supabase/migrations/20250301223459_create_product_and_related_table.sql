create sequence "public"."categories_category_id_seq";

create sequence "public"."products_product_id_seq";

create sequence "public"."sizes_size_id_seq";

create sequence "public"."temperature_types_temperature_type_id_seq";

create table "public"."categories" (
    "category_id" integer not null default nextval('categories_category_id_seq'::regclass),
    "category_name" character varying(50) not null,
    "description" text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
);


create table "public"."product_sizes" (
    "product_id" integer not null,
    "size_id" integer not null,
    "price" integer not null
);


create table "public"."product_temperature_types" (
    "product_id" integer not null,
    "temperature_type_id" integer not null
);


create table "public"."products" (
    "product_id" integer not null default nextval('products_product_id_seq'::regclass),
    "product_name" character varying(100) not null,
    "category_id" integer,
    "description" text,
    "is_active" boolean default true,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
);


create table "public"."sizes" (
    "size_id" integer not null default nextval('sizes_size_id_seq'::regclass),
    "size_name" character varying(10) not null,
    "size_description" character varying(100)
);


create table "public"."temperature_types" (
    "temperature_type_id" integer not null default nextval('temperature_types_temperature_type_id_seq'::regclass),
    "type_name" character varying(20) not null
);


alter sequence "public"."categories_category_id_seq" owned by "public"."categories"."category_id";

alter sequence "public"."products_product_id_seq" owned by "public"."products"."product_id";

alter sequence "public"."sizes_size_id_seq" owned by "public"."sizes"."size_id";

alter sequence "public"."temperature_types_temperature_type_id_seq" owned by "public"."temperature_types"."temperature_type_id";

CREATE UNIQUE INDEX categories_pkey ON public.categories USING btree (category_id);

CREATE INDEX idx_product_sizes ON public.product_sizes USING btree (product_id);

CREATE INDEX idx_product_temperature ON public.product_temperature_types USING btree (product_id);

CREATE INDEX idx_products_category ON public.products USING btree (category_id);

CREATE UNIQUE INDEX product_sizes_pkey ON public.product_sizes USING btree (product_id, size_id);

CREATE UNIQUE INDEX product_temperature_types_pkey ON public.product_temperature_types USING btree (product_id, temperature_type_id);

CREATE UNIQUE INDEX products_pkey ON public.products USING btree (product_id);

CREATE UNIQUE INDEX sizes_pkey ON public.sizes USING btree (size_id);

CREATE UNIQUE INDEX temperature_types_pkey ON public.temperature_types USING btree (temperature_type_id);

alter table "public"."categories" add constraint "categories_pkey" PRIMARY KEY using index "categories_pkey";

alter table "public"."product_sizes" add constraint "product_sizes_pkey" PRIMARY KEY using index "product_sizes_pkey";

alter table "public"."product_temperature_types" add constraint "product_temperature_types_pkey" PRIMARY KEY using index "product_temperature_types_pkey";

alter table "public"."products" add constraint "products_pkey" PRIMARY KEY using index "products_pkey";

alter table "public"."sizes" add constraint "sizes_pkey" PRIMARY KEY using index "sizes_pkey";

alter table "public"."temperature_types" add constraint "temperature_types_pkey" PRIMARY KEY using index "temperature_types_pkey";

alter table "public"."product_sizes" add constraint "product_sizes_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(product_id) not valid;

alter table "public"."product_sizes" validate constraint "product_sizes_product_id_fkey";

alter table "public"."product_sizes" add constraint "product_sizes_size_id_fkey" FOREIGN KEY (size_id) REFERENCES sizes(size_id) not valid;

alter table "public"."product_sizes" validate constraint "product_sizes_size_id_fkey";

alter table "public"."product_temperature_types" add constraint "product_temperature_types_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(product_id) not valid;

alter table "public"."product_temperature_types" validate constraint "product_temperature_types_product_id_fkey";

alter table "public"."product_temperature_types" add constraint "product_temperature_types_temperature_type_id_fkey" FOREIGN KEY (temperature_type_id) REFERENCES temperature_types(temperature_type_id) not valid;

alter table "public"."product_temperature_types" validate constraint "product_temperature_types_temperature_type_id_fkey";

alter table "public"."products" add constraint "products_category_id_fkey" FOREIGN KEY (category_id) REFERENCES categories(category_id) not valid;

alter table "public"."products" validate constraint "products_category_id_fkey";

grant delete on table "public"."categories" to "anon";

grant insert on table "public"."categories" to "anon";

grant references on table "public"."categories" to "anon";

grant select on table "public"."categories" to "anon";

grant trigger on table "public"."categories" to "anon";

grant truncate on table "public"."categories" to "anon";

grant update on table "public"."categories" to "anon";

grant delete on table "public"."categories" to "authenticated";

grant insert on table "public"."categories" to "authenticated";

grant references on table "public"."categories" to "authenticated";

grant select on table "public"."categories" to "authenticated";

grant trigger on table "public"."categories" to "authenticated";

grant truncate on table "public"."categories" to "authenticated";

grant update on table "public"."categories" to "authenticated";

grant delete on table "public"."categories" to "service_role";

grant insert on table "public"."categories" to "service_role";

grant references on table "public"."categories" to "service_role";

grant select on table "public"."categories" to "service_role";

grant trigger on table "public"."categories" to "service_role";

grant truncate on table "public"."categories" to "service_role";

grant update on table "public"."categories" to "service_role";

grant delete on table "public"."product_sizes" to "anon";

grant insert on table "public"."product_sizes" to "anon";

grant references on table "public"."product_sizes" to "anon";

grant select on table "public"."product_sizes" to "anon";

grant trigger on table "public"."product_sizes" to "anon";

grant truncate on table "public"."product_sizes" to "anon";

grant update on table "public"."product_sizes" to "anon";

grant delete on table "public"."product_sizes" to "authenticated";

grant insert on table "public"."product_sizes" to "authenticated";

grant references on table "public"."product_sizes" to "authenticated";

grant select on table "public"."product_sizes" to "authenticated";

grant trigger on table "public"."product_sizes" to "authenticated";

grant truncate on table "public"."product_sizes" to "authenticated";

grant update on table "public"."product_sizes" to "authenticated";

grant delete on table "public"."product_sizes" to "service_role";

grant insert on table "public"."product_sizes" to "service_role";

grant references on table "public"."product_sizes" to "service_role";

grant select on table "public"."product_sizes" to "service_role";

grant trigger on table "public"."product_sizes" to "service_role";

grant truncate on table "public"."product_sizes" to "service_role";

grant update on table "public"."product_sizes" to "service_role";

grant delete on table "public"."product_temperature_types" to "anon";

grant insert on table "public"."product_temperature_types" to "anon";

grant references on table "public"."product_temperature_types" to "anon";

grant select on table "public"."product_temperature_types" to "anon";

grant trigger on table "public"."product_temperature_types" to "anon";

grant truncate on table "public"."product_temperature_types" to "anon";

grant update on table "public"."product_temperature_types" to "anon";

grant delete on table "public"."product_temperature_types" to "authenticated";

grant insert on table "public"."product_temperature_types" to "authenticated";

grant references on table "public"."product_temperature_types" to "authenticated";

grant select on table "public"."product_temperature_types" to "authenticated";

grant trigger on table "public"."product_temperature_types" to "authenticated";

grant truncate on table "public"."product_temperature_types" to "authenticated";

grant update on table "public"."product_temperature_types" to "authenticated";

grant delete on table "public"."product_temperature_types" to "service_role";

grant insert on table "public"."product_temperature_types" to "service_role";

grant references on table "public"."product_temperature_types" to "service_role";

grant select on table "public"."product_temperature_types" to "service_role";

grant trigger on table "public"."product_temperature_types" to "service_role";

grant truncate on table "public"."product_temperature_types" to "service_role";

grant update on table "public"."product_temperature_types" to "service_role";

grant delete on table "public"."products" to "anon";

grant insert on table "public"."products" to "anon";

grant references on table "public"."products" to "anon";

grant select on table "public"."products" to "anon";

grant trigger on table "public"."products" to "anon";

grant truncate on table "public"."products" to "anon";

grant update on table "public"."products" to "anon";

grant delete on table "public"."products" to "authenticated";

grant insert on table "public"."products" to "authenticated";

grant references on table "public"."products" to "authenticated";

grant select on table "public"."products" to "authenticated";

grant trigger on table "public"."products" to "authenticated";

grant truncate on table "public"."products" to "authenticated";

grant update on table "public"."products" to "authenticated";

grant delete on table "public"."products" to "service_role";

grant insert on table "public"."products" to "service_role";

grant references on table "public"."products" to "service_role";

grant select on table "public"."products" to "service_role";

grant trigger on table "public"."products" to "service_role";

grant truncate on table "public"."products" to "service_role";

grant update on table "public"."products" to "service_role";

grant delete on table "public"."sizes" to "anon";

grant insert on table "public"."sizes" to "anon";

grant references on table "public"."sizes" to "anon";

grant select on table "public"."sizes" to "anon";

grant trigger on table "public"."sizes" to "anon";

grant truncate on table "public"."sizes" to "anon";

grant update on table "public"."sizes" to "anon";

grant delete on table "public"."sizes" to "authenticated";

grant insert on table "public"."sizes" to "authenticated";

grant references on table "public"."sizes" to "authenticated";

grant select on table "public"."sizes" to "authenticated";

grant trigger on table "public"."sizes" to "authenticated";

grant truncate on table "public"."sizes" to "authenticated";

grant update on table "public"."sizes" to "authenticated";

grant delete on table "public"."sizes" to "service_role";

grant insert on table "public"."sizes" to "service_role";

grant references on table "public"."sizes" to "service_role";

grant select on table "public"."sizes" to "service_role";

grant trigger on table "public"."sizes" to "service_role";

grant truncate on table "public"."sizes" to "service_role";

grant update on table "public"."sizes" to "service_role";

grant delete on table "public"."temperature_types" to "anon";

grant insert on table "public"."temperature_types" to "anon";

grant references on table "public"."temperature_types" to "anon";

grant select on table "public"."temperature_types" to "anon";

grant trigger on table "public"."temperature_types" to "anon";

grant truncate on table "public"."temperature_types" to "anon";

grant update on table "public"."temperature_types" to "anon";

grant delete on table "public"."temperature_types" to "authenticated";

grant insert on table "public"."temperature_types" to "authenticated";

grant references on table "public"."temperature_types" to "authenticated";

grant select on table "public"."temperature_types" to "authenticated";

grant trigger on table "public"."temperature_types" to "authenticated";

grant truncate on table "public"."temperature_types" to "authenticated";

grant update on table "public"."temperature_types" to "authenticated";

grant delete on table "public"."temperature_types" to "service_role";

grant insert on table "public"."temperature_types" to "service_role";

grant references on table "public"."temperature_types" to "service_role";

grant select on table "public"."temperature_types" to "service_role";

grant trigger on table "public"."temperature_types" to "service_role";

grant truncate on table "public"."temperature_types" to "service_role";

grant update on table "public"."temperature_types" to "service_role";

