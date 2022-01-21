-- B, create tables
-- B.detailed
CREATE TABLE IF NOT EXISTS public.active_rentals_detail(
    rental_id INT NOT NULL PRIMARY KEY,
    rental_date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    rental_duration INT NOT NULL,
    film_title VARCHAR(255),
    inventory_id INT NOT NULL,
    due_date DATE,
    customer_id INT NOT NULL,
    customer_full_name VARCHAR(92),
    customer_email VARCHAR(50),
    customer_phone VARCHAR(20),
    store_id INT NOT NULL,
    last_updated TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    FOREIGN KEY (inventory_id) REFERENCES inventory(inventory_id) ON DELETE NO ACTION,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON DELETE NO ACTION,
    FOREIGN KEY (store_id) REFERENCES store(store_id) ON DELETE NO ACTION,
    FOREIGN KEY (rental_id) REFERENCES rental(rental_id) ON DELETE NO ACTION
);
DROP TRIGGER IF EXISTS last_updated ON public.active_rentals_detail;
CREATE TRIGGER last_updated
    BEFORE UPDATE 
    ON public.active_rentals_detail
    FOR EACH ROW
    EXECUTE FUNCTION public.last_updated();

-- B.summary.update-trigger
CREATE OR REPLACE FUNCTION public.populate_summary_trigger()
    RETURNS TRIGGER
    LANGUAGE 'plpgsql'
    AS $BODY$
    BEGIN
        PERFORM public.populate_summary_data();
    END
    $BODY$;

ALTER FUNCTION public.populate_summary_trigger()
    OWNER TO postgres;

CREATE OR REPLACE FUNCTION public.populate_summary_data()
    RETURNS void
    LANGUAGE 'plpgsql'
    AS $BODY$
    BEGIN
        TRUNCATE TABLE public.active_rentals_summary;
        INSERT INTO public.active_rentals_summary
        SELECT customer_id, customer_full_name, customer_email, customer_phone, store_id, COUNT(*), now()
            FROM active_rentals_detail
            GROUP BY (customer_id, customer_full_name, customer_email, customer_phone, store_id);
    END
    $BODY$;

ALTER FUNCTION public.populate_summary_data()
    OWNER TO postgres;

DROP TRIGGER IF EXISTS update_active_rentals_summary ON public.active_rentals_detail;
CREATE TRIGGER update_active_rentals_summary 
    AFTER UPDATE
    ON public.active_rentals_detail
    EXECUTE FUNCTION public.populate_summary_trigger();

-- B.summary
CREATE TABLE IF NOT EXISTS public.active_rentals_summary(
    customer_id INT NOT NULL,
    customer_full_name VARCHAR(92),
    customer_email VARCHAR(50),
    customer_phone VARCHAR(20),
    store_id INT NOT NULL,
    quantity_active_rentals INT NOT NULL,
    last_updated TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    FOREIGN KEY (store_id) REFERENCES store(store_id) ON DELETE NO ACTION,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON DELETE NO ACTION,
    FOREIGN KEY (store_id) REFERENCES store(store_id) ON DELETE NO ACTION
);

DROP TRIGGER IF EXISTS last_updated ON public.active_rentals_summary;
CREATE TRIGGER last_updated
    BEFORE UPDATE 
    ON public.active_rentals_summary
    FOR EACH ROW
    EXECUTE FUNCTION public.last_updated();



-- D Create transformation function
CREATE OR REPLACE FUNCTION public.build_full_name(first_name TEXT, last_name TEXT)
    RETURNS TEXT
    LANGUAGE 'plpgsql'
	AS $BODY$
	BEGIN
        RETURN CONCAT(first_name, ' ', last_name);
    END 
    $BODY$;
    
	
ALTER FUNCTION public.build_full_name(TEXT, TEXT)
    OWNER TO postgres;


-- C extraction query

CREATE OR REPLACE FUNCTION public.find_due_date(start_time TIMESTAMP WITHOUT TIME ZONE, rental_duration INT)
    RETURNS DATE
    LANGUAGE 'plpgsql'
    AS $BODY$
    DECLARE 
        due_date DATE;
        duration TEXT;
        due_timestamp TIMESTAMP WITHOUT TIME ZONE;
        due_day INT;
        due_month INT;
        due_year INT;
    BEGIN
        due_timestamp := start_time + make_interval(days => rental_duration);
        due_day := extract (DAY FROM due_timestamp);
        due_month := extract (MONTH FROM due_timestamp);
        due_year := extract (YEAR FROM due_timestamp);
        due_date := make_date(due_year, due_month, due_day);
    RETURN due_date;
    END
    $BODY$;

ALTER FUNCTION public.find_due_date(TIMESTAMP WITHOUT TIME ZONE, INT)
    OWNER TO postgres;


CREATE OR REPLACE FUNCTION public.populate_detail_data()
    RETURNS void
    LANGUAGE 'plpgsql'
    AS $BODY$
    BEGIN
        INSERT INTO public.active_rentals_detail 
        SELECT 
            r.rental_id,
            r.rental_date, 
            f.rental_duration, 
            f.title, 
            i.inventory_id, 
            find_due_date(r.rental_date, f.rental_duration) as due_date,
            c.customer_id, 
            build_full_name(c.first_name, c.last_name), 
            c.email,
            a.phone, 
            i.store_id, 
            now()
        FROM rental r
        INNER JOIN customer c on r.customer_id=c.customer_id
        INNER JOIN inventory i on r.inventory_id=i.inventory_id
        INNER JOIN film f on i.film_id=f.film_id
        INNER JOIN address a ON c.address_id=a.address_id
        WHERE r.return_date IS NULL
        ORDER BY r.rental_id asc;
    END
    $BODY$;

ALTER FUNCTION public.populate_detail_data()
    OWNER TO postgres;

CREATE OR REPLACE PROCEDURE active_rentals_refresh()
    /*
    * This procedure should be run nightly, or more often, as needed.
    * It would be best to automate this procedure this using some sort of task scheduler, 
    * or general purpose programming language.
    */
    LANGUAGE 'plpgsql'
    AS $BODY$
    BEGIN
        TRUNCATE TABLE public.active_rentals_detail;
        PERFORM public.populate_detail_data();
        PERFORM public.populate_summary_data();
    END;
    $BODY$;

ALTER PROCEDURE active_rentals_refresh()
    OWNER TO postgres;
