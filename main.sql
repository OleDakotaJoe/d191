-- B, create tables
CREATE TABLE active_rentals_detail(
    rental_id INT NOT NULL PRIMARY KEY,
    rental_date DATE NOT NULL,
    rental_duration INT NOT NULL,
    film_title VARCHAR(255),
    inventory_id INT NOT NULL,
    due_date DATE NOT NULL,
    customer_id INT NOT NULL,
    customer_full_name VARCHAR(512),
    customer_email VARCHAR(255),
    customer_phone VARCHAR(255),
    store_id INT NOT NULL,
    last_updated DATE NOT NULL,
    FOREIGN KEY (inventory_id) REFERENCES inventory(inventory_id) ON DELETE NO ACTION,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON DELETE NO ACTION,
    FOREIGN KEY (store_id) REFERENCES store(store_id) ON DELETE NO ACTION,
    FOREIGN KEY (rental_id) REFERENCES rental(rental_id) ON DELETE NO ACTION
);

CREATE TABLE active_rentals_summary(
    customer_id INT NOT NULL PRIMARY KEY,
    customer_full_name VARCHAR(512),
    customer_email VARCHAR(255),
    customer_phone VARCHAR(255),
    store_id INT NOT NULL,
    quantity_active_rentals INT NOT NULL,
    last_updated DATE NOT NULL,
    FOREIGN KEY (store_id) REFERENCES store(store_id) ON DELETE NO ACTION,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON DELETE NO ACTION,
    FOREIGN KEY (store_id) REFERENCES store(store_id) ON DELETE NO ACTION
);









