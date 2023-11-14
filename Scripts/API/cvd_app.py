# In the CLI:   flask --app cvd_app run --port 8080 [--debug]

import os
import json
import math
from collections import defaultdict 

from flask import Flask, request
# from flask_basicauth import BasicAuth

import pymysql



MAX_PAGE_SIZE = 50

app = Flask(__name__)


@app.route("/help")
def hello_api():
   # Help file

    return {"hey": "I'm the API!",
            "message": """Instructions to access the data:

End Point 1:   http://localhost:8080/persons/123
This API gives all the information available for a given person based on his ID.

End Point 2:   http://localhost:8080/persons?page=2&page_size=5
This API allows the user to request all the information in the main table from BRFSS. As there are 275k persons in the database, the user can add the optional parameters page and page_size to display the data for the page number chosen on the basis of the page_size given.
The API returns the data requested and the url of the next page and the url of the last possible page.

End Point 3:   http://localhost:8080/states/pollution/texas
This API gives the air pollution level for the chosen state.

End Point 4:   http://localhost:8080/states/population/california
This API gives the population for the chosen state.
"""
}


@app.route("/persons")
def movies():
    # optional parameter:  http://localhost:8080/persons?page=2&page_size=10

    page = int(request.args.get('page', 0))   
    page_size = int(request.args.get('page_size', MAX_PAGE_SIZE))
    page_size = min(page_size, MAX_PAGE_SIZE)

    db_conn = pymysql.connect(host="localhost", user="root", database="cvd",
                              password=os.getenv('mysql_rq'),
                              cursorclass=pymysql.cursors.DictCursor)
    with db_conn.cursor() as cursor:
        cursor.execute("""
            SELECT * FROM brfss2021_cleaned b 
            ORDER BY person_id
            LIMIT %s
            OFFSET %s
        """, (page_size, page * page_size))
        persons = cursor.fetchall()

    with db_conn.cursor() as cursor:
        cursor.execute("SELECT COUNT(*) AS total FROM brfss2021_cleaned")
        total = cursor.fetchone()
        print(total['total'])
        last_page = math.ceil(total['total'] / page_size)

    db_conn.close()

    return {'persons': persons,   #{'mmm':list_s , "ppp":movies_id #
        'next_page': f'/persons?page={page+1}&page_size={page_size}',
        'last_page': f'/persons?page={last_page}&page_size={page_size}',
    }


@app.route("/persons/<int:person_id>")   
# @auth.required
def person(person_id):
    # compulsory parameter:   http://localhost:8080/persons/123

    db_conn = pymysql.connect(host="localhost", user="root", database="cvd",
                              password=os.getenv('mysql_rq'),
                              cursorclass=pymysql.cursors.DictCursor)

    with db_conn.cursor() as cursor:
        cursor.execute("""
            SELECT * FROM brfss2021_cleaned
            WHERE person_id = %s
        """, (person_id))
        person = cursor.fetchone()

    db_conn.close()
    # print(type(person), person)

    return person


@app.route("/states/pollution/<state_name>")   
def state_pollution(state_name): 
    # compulsory parameter:   http://localhost:8080/states/california
    # todo: parameter validation

    db_conn = pymysql.connect(host="localhost", user="root", database="cvd",
                              password=os.getenv('mysql_rq'),
                              cursorclass=pymysql.cursors.DictCursor)

    with db_conn.cursor() as cursor:
        cursor.execute("""
            SELECT p.`Air Pollution`
            FROM pollution_2021 p
            WHERE p.State = %s
            #LIMIT 10
        """, (state_name))
        pollution = cursor.fetchone()

    db_conn.close()
    #print(type(pollution), pollution, state_name)

    #return {'tt1':state_name, 'tt2':type(pollution), 'tt3':pollution}
    return pollution


@app.route("/states/population/<state_name>")   
def state_population(state_name): 
    # compulsory parameter:   http://localhost:8080/states/california
    # todo: parameter validation

    db_conn = pymysql.connect(host="localhost", user="root", database="cvd",
                              password=os.getenv('mysql_rq'),
                              cursorclass=pymysql.cursors.DictCursor)

    with db_conn.cursor() as cursor:
        cursor.execute("""
            SELECT p.`Population`
            FROM population_2021 p
            WHERE p.State = %s
        """, (state_name))
        population = cursor.fetchone()

    db_conn.close()

    return population