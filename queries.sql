-- CALL PROCEDURE

CALL active_rentals_refresh();


-- CHECK DETAIL REPORT

SELECT * FROM active_rentals_detail;

-- CHECK SUMMARY REPORT

SELECT * FROM active_rentals_summary;


