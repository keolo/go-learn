package main

import (
    "encoding/json"
    "log"
    "net/http"
    "github.com/gorilla/mux"
    "gopkg.in/mgo.v2"
    "gopkg.in/mgo.v2/bson"
)

type Person struct {
    ID        string   `json:"id,omitempty"`
    Firstname string   `json:"firstname,omitempty"`
    Lastname  string   `json:"lastname,omitempty"`
    Address   *Address `json:"address,omitempty"`
}

type Address struct {
    City  string `json:"city,omitempty"`
    State string `json:"state,omitempty"`
}

var people []Person

func GetLivenessEndpoint(w http.ResponseWriter, req *http.Request) {
    log.Println(req)
    w.WriteHeader(http.StatusNoContent)
}

func GetReadinessEndpoint(w http.ResponseWriter, req *http.Request) {
    log.Println(req)
    // TODO: Add application checks like db connection, etc
    w.WriteHeader(http.StatusNoContent)
}

func GetPersonEndpoint(w http.ResponseWriter, req *http.Request) {
    params := mux.Vars(req)
    for _, item := range people {
        if item.ID == params["id"] {
            json.NewEncoder(w).Encode(item)
            return
        }
    }
    json.NewEncoder(w).Encode(&Person{})
}

func GetPeopleEndpoint(w http.ResponseWriter, req *http.Request) {
    json.NewEncoder(w).Encode(people)
}

func CreatePersonEndpoint(w http.ResponseWriter, req *http.Request) {
    params := mux.Vars(req)
    var person Person
    _ = json.NewDecoder(req.Body).Decode(&person)
    person.ID = params["id"]
    people = append(people, person)
    json.NewEncoder(w).Encode(people)
}

func DeletePersonEndpoint(w http.ResponseWriter, req *http.Request) {
    params := mux.Vars(req)
    for index, item := range people {
        if item.ID == params["id"] {
            people = append(people[:index], people[index+1:]...)
            break
        }
    }
    json.NewEncoder(w).Encode(people)
}

type Animal struct {
    Kind string
    Name string
}

func main() {
    // TODO: Make the hostname dynamic by using an env var
    session, err := mgo.Dial("go-learn-local-mongodb")
    if err != nil {
        panic(err)
    }
    defer session.Close()

    // Optional. Switch the session to a monotonic behavior.
    // session.SetMode(mgo.Monotonic, true)

    c := session.DB("test").C("animal")
    err = c.Insert(&Animal{Kind: "Dog", Name: "Woofy"},
                   &Animal{Kind: "Cat", Name: "Kitty"})
    if err != nil {
        log.Fatal(err)
    }

    result := Animal{}
    err = c.Find(bson.M{"name": "Woofy"}).One(&result)

    log.Println(result)

    if err != nil {
        log.Print(err)
        log.Print(result)
    }

    router := mux.NewRouter()
    people = append(people, Person{ID: "1", Firstname: "Niki", Lastname: "Lauder", Address: &Address{City: "Dublin", State: "CA"}})
    people = append(people, Person{ID: "2", Firstname: "James", Lastname: "Hunt"})
    router.HandleFunc("/liveness", GetLivenessEndpoint).Methods("GET")
    router.HandleFunc("/readiness", GetLivenessEndpoint).Methods("GET")
    router.HandleFunc("/people", GetPeopleEndpoint).Methods("GET")
    router.HandleFunc("/people/{id}", GetPersonEndpoint).Methods("GET")
    router.HandleFunc("/people/{id}", CreatePersonEndpoint).Methods("POST")
    router.HandleFunc("/people/{id}", DeletePersonEndpoint).Methods("DELETE")
    log.Fatal(http.ListenAndServe(":8080", router))
}
