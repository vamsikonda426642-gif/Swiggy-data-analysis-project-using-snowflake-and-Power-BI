-- use sysadmin role.
use role sysadmin;
--- Create database and schema if does not exist 
create database if not exists sandbox;
CREATE schema if not exists stage_sch;
CREATE schema if not exists clean_sch;
CREATE schema if not exists consumption_sch;
CREATE schema if not exists common;

----- First we need to create the file format and uplaod the data from CSV to stage 

use schema stage_sch;

 -- create file format to process the CSV file
  create file format if not exists stage_sch.csv_file_format 
        type = 'csv' 
        compression = 'auto' 
        field_delimiter = ',' 
        record_delimiter = '\n' 
        skip_header = 1 
        field_optionally_enclosed_by = '\042' 
        null_if = ('\\N');

create stage stage_sch.csv_stg
    directory = ( enable = true )
    comment = 'this is the snowflake internal stage';


create or replace tag 
    common.pii_policy_tag 
    allowed_values 'PII','PRICE','SENSITIVE','EMAIL'
    comment = 'This is PII policy tag object';

create or replace masking policy 
    common.pii_masking_policy as (pii_text string)
    returns string -> 
    to_varchar('** PII **');

create or replace masking policy 
    common.email_masking_policy as (email_text string)
    returns string -> 
    to_varchar('** EAMIL **');

create or replace masking policy 
    common.phone_masking_policy as (phone string)
    returns string -> 
    to_varchar('** Phone **');

list @stage_sch.csv_stg

