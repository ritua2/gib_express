/*
BASICS

Redirects a user, doing all the necessary actions
Checks that a user is valid after login into wetty
*/


package main

import (
    "errors"
    "fmt"
    "github.com/gorilla/mux"
    "github.com/go-redis/redis"
    "encoding/json"
    "math"
    "math/rand"
    "net/http"
    "os"
    "strconv"
    "strings"
    "time"
)


// Process uploaded keys
type Provided_Parameters struct {
    // Actor identifier
    Sender string
    // Key used
    Key  string
}


// Attachment information for an instance
type Attach_Info struct {
    // Actor identifier
    Sender string
    // Key used
    Key  string
    // Port
    Port string
}


// Source seed for random number generators
var src = rand.NewSource(time.Now().UnixNano())
const letterBytes = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
const (
    letterIdxBits = 6                    // 6 bits to represent a letter index
    letterIdxMask = 1<<letterIdxBits - 1 // All 1-bits, as many as letterIdxBits
    letterIdxMax  = 63 / letterIdxBits   // # of letter indices fitting in 63 bits
)


var credential string = os.Getenv("orchestra_key")
var redauth string = os.Getenv("REDIS_AUTH")
var URL_BASE string = os.Getenv("URL_BASE")
var PROJECT string = os.Getenv("PROJECT")

var rurl =[]string{URL_BASE, ":6379"}
var rurl2 string = strings.Join(rurl, "")

// Obtains the permissions for greyfish
var GREYFISH_URL string = os.Getenv("GREYFISH_URL")
var GREYFISH_REDIS_KEY = os.Getenv("GREYFISH_REDIS_KEY")
var greyurl string = Sadder(GREYFISH_URL, ":6379")


// Creates a redis client for keeping tracking of which user is on which 
// Uses redis hashes 
var r_occupied *redis.Client = redis.NewClient(&redis.Options{
    Addr: rurl2,
    Password: redauth,
    DB:0,
    })


// Creates a temporary cache for user redirections and similar
var r_redirect_cache *redis.Client = redis.NewClient(&redis.Options{
    Addr: rurl2,
    Password: redauth,
    DB:1,
    })


// Greyfish temporary token storage
var greyfish_server *redis.Client = redis.NewClient(&redis.Options{
    Addr: greyurl,
    Password: GREYFISH_REDIS_KEY,
    DB:3,
    })

// Greyfish temporary token storage
var misc *redis.Client = redis.NewClient(&redis.Options{
    Addr: rurl2,
    Password: redauth,
    DB:4,
    })




func main(){

    r := mux.NewRouter()

    r.HandleFunc("/api/scripts/startup", Startup_supplier).Methods("GET")
    r.HandleFunc("/api/project/name", Project_name).Methods("GET")
    r.HandleFunc("/api/status/containers/available", AvCon_API).Methods("GET")
    r.HandleFunc("/api/active", Checker).Methods("GET")
    r.HandleFunc("/api/assign/users/{user_id}", Assigner).Methods("POST")
    r.HandleFunc("/api/redirect/users/{user_id}/{target_ip}", Redirect).Methods("GET")
    r.HandleFunc("/api/instance/attachme", Attachme).Methods("POST")
    r.HandleFunc("/api/instance/removeme", Removeme).Methods("POST")
    r.HandleFunc("/api/instance/remove_my_port", Remove_my_port).Methods("POST")
    r.HandleFunc("/api/instance/freeme/{uf10}", Freeme).Methods("GET")
    r.HandleFunc("/api/instance/whoami/{uf10}", Whoami).Methods("GET")
    r.HandleFunc("/api/instance/whatsmyip", Whatsmyip).Methods("GET")

    // Greyfish handlers
    r.HandleFunc("/api/greyfish/location", Grey_locator).Methods("GET")
    r.HandleFunc("/api/greyfish/new/single_use_token/{uf10}", Grey_stoken).Methods("GET")

    http.Handle("/", r)


    // Always listening in port 5000
    http.ListenAndServe(":5000", r)
}


// Returns the startup script
func Startup_supplier(w http.ResponseWriter, r *http.Request) {
    http.ServeFile(w, r, "/scripts/startup.sh")
}


// Returns the project name
func Project_name(w http.ResponseWriter, r *http.Request) {
    fmt.Fprintf(w, "%s", PROJECT)
}


// Returns a string of the available docker containers
func AvCon_API(w http.ResponseWriter, r *http.Request) {
    fmt.Fprintf(w, "%s", available_containers())
}


// Simple API check
func Checker(w http.ResponseWriter, r *http.Request){
    fmt.Fprintf(w, "Orchestration node is active")
}


// Returns the location of the greyfish server (without 'http://')
func Grey_locator(w http.ResponseWriter, r *http.Request){
    fmt.Fprintf(w, "%s", GREYFISH_URL)
}


// Creates a new key for the user located at the present instance
// Simply returns the key
// Cannot be called from outside the instance

func Grey_stoken (w http.ResponseWriter, r *http.Request){

    reqip := ip_only(r.RemoteAddr)
    instances := redkeys(r_occupied)
    // First 10 charachers of password
    UID10 := mux.Vars(r)["uf10"]

    if stringInSlice(reqip, instances) {

        // Checks the port number of the instance
        pnn, err := Porter10(reqip, UID10)

        if err != nil {
                fmt.Fprintf(w, "INVALID: port not attached")
        } else {

            // Gets the associated username
            curuser, _ := r_occupied.HGet(reqip, Sadder("current_user_", pnn)).Result()

            if curuser != "Empty"{
                // Creates a random string of characters (24 length), sets it as a token, and returns it
                // Each token will last a maximum of 2 hours
                new_token := random_string(24)
                greyfish_server.Set(new_token, curuser, 7200*time.Second)
                fmt.Fprintf(w, "%s", new_token)
            }
        }
    } else {
        fmt.Fprintf(w, "INVALID: instance not attached")
    }
}


// Validates a user, requires json information about the user
// Creates an empty redis key with information
func Assigner(w http.ResponseWriter, r *http.Request){

    UID := mux.Vars(r)["user_id"]
    var ppr Provided_Parameters
    err := json.NewDecoder(r.Body).Decode(&ppr)

    if err != nil {
        fmt.Fprintf(w, "POST parameters could not be parsed")
    } else {

        key := ppr.Key
        all_instances_occupied := true

        if valid_adm_passwd(key){
            // Checks all instances with at least one port open
            for _, instance := range available_instances(){
                instance_ := Sadder(instance, "_")

                // Only ports not assigned yet
                for _, emp := range empty_ports(instance){

                    if red_key_check(r_redirect_cache, Sadder(instance_, emp)){
                        // Ignores ports in cache
                        continue
                    }
                    // Sets the instance as occupied, server now has 20 s to redirect user
                    r_redirect_cache.Set(Sadder(instance_, emp), UID, 20*time.Second)
                    fmt.Fprintf(w, "%s", Sadder(Sadder(instance, ":"), emp))
                    all_instances_occupied = false
                    break
                }
                if ! all_instances_occupied{
                    break
                }
            }

            if all_instances_occupied {
                fmt.Fprintf(w, "False")
            }

        } else {
            fmt.Fprintf(w, "INVALID key")
        }
    }
}


// Redirects a user after an available IP has been provided to him
func Redirect (w http.ResponseWriter, r *http.Request){

    UID := mux.Vars(r)["user_id"]
    TIP := mux.Vars(r)["target_ip"]

    // Finds if the user is attached at any instance
    user_instance := "NA"
    available_redirect, _ := r_redirect_cache.Keys(Sadder(TIP, "*")).Result()
    for _, avred := range available_redirect{
        expected_user, err := r_redirect_cache.Get(avred).Result()
        if err == redis.Nil{
            continue
        }
        if expected_user == UID{
            user_instance = avred
            break
        }
    }

    if user_instance == "NA"{
        fmt.Fprintf(w, "INVALID: %s has already been assigned to another user", TIP)
    } else {
        // Deletes the redis copy
        r_redirect_cache.Del(user_instance)
        // Gets the port number
        user_instance = strings.Replace(user_instance, "_", ":", 1)

        // 20 s to complete redirect
        r_redirect_cache.Set(user_instance, UID, 20*time.Second)

        // Automatic login by: wetty/ssh/<username>?sshpass=<password>

        http.Redirect(w, r, Sadder("http://", user_instance), 302)
    }
}


// Adds the caller IP as a wetty instance
func Attachme (w http.ResponseWriter, r *http.Request){
    var ppr Attach_Info

    err := json.NewDecoder(r.Body).Decode(&ppr)

    if err != nil {
        fmt.Fprintf(w, "POST parameters could not be parsed")
    } else {

        key := ppr.Key
        // Each IP has to identify itself
        sender_ID := ppr.Sender
        // There may be multiple containers per instance
        iport := ppr.Port
        reqip := ip_only(r.RemoteAddr)

        if valid_adm_passwd(key){

            // Checks all the current instances
            instances := redkeys(r_occupied)
            port_number, _ := strconv.Atoi(iport)

            if stringInSlice(reqip, instances) {

                // Avoids adding already added ports
                occports := ports_occupied(reqip)
                if ! stringInSlice(iport, occports){
                    // Append new port information
                    r_occupied.HIncrBy(reqip, "Ports", int64(math.Pow(2, float64((port_number-7000)%10))))

                    var available interface{} = "Yes"
                    var current_user interface{} = "Empty"
                    var id interface{} = sender_ID

                    // Resets instance
                    r_occupied.HSet(reqip, strings.Join([]string{"Available", iport}, "_"), available)
                    r_occupied.HSet(reqip, strings.Join([]string{"current_user", iport}, "_"), current_user)
                    r_occupied.HSet(reqip, strings.Join([]string{"id", iport}, "_"), id)
                    change_container_availability(1)
                    fmt.Fprintf(w, "Added port %s", iport)
                } else {
                    fmt.Fprintf(w, "Port has already been added")
                }

            } else {
                // Create new instance hash
                // All IPs are stored in Redis with the following data:
                // Available, id, current_user, whoami_count, address
                var new_instance = make(map[string]interface{})
                new_instance["address"] = reqip
                new_instance["Available"] = "Yes"
                new_instance["Ports"] = strconv.Itoa(int(math.Pow(2, float64((port_number-7000)%10))))

                // Varies per instance
                new_instance[strings.Join([]string{"id", iport}, "_")] = sender_ID
                new_instance[strings.Join([]string{"current_user", iport}, "_")] = "Empty"
                new_instance[strings.Join([]string{"Available", iport}, "_")] = "Yes"
                _, e2 := r_occupied.HMSet(reqip, new_instance).Result()

                if e2 != nil {
                    fmt.Fprintf(w, "Server error, Redis is not attached")
                } else{
                    change_container_availability(1)
                    fmt.Fprintf(w, "Instance correctly attached")
                }
            }

        } else {
            fmt.Fprintf(w, "INVALID key")
        }
    }
}


// Removes the current IP as a wetty instance
func Removeme (w http.ResponseWriter, r *http.Request) {

    var ppr Provided_Parameters
    err := json.NewDecoder(r.Body).Decode(&ppr)

    if err != nil {
        fmt.Fprintf(w, "POST parameters could not be parsed")
    } else {

        key := ppr.Key
        reqip := ip_only(r.RemoteAddr)

        if valid_adm_passwd(key){

            if ! stringInSlice(reqip, redkeys(r_occupied)){
               fmt.Fprintf(w, "INVALID, instance is not associated with the project")
            } else {
                    _, e2 := r_occupied.Del(reqip).Result()

                    switch e2 {
                    case nil:
                        change_container_availability(-1)
                        fmt.Fprintf(w, "Instance removed")
                    default:
                        fmt.Fprintf(w, "Server error, Redis is not attached")
                    }
                }
        } else {
                fmt.Fprintf(w, "INVALID key")
        }
    }
}


// Removes a port from an instance
// If the instance has no more ports, it deletes it
// This is an instantaneous action and it does not matter if there is a user already in the instance

func Remove_my_port (w http.ResponseWriter, r *http.Request) {

    var ppr Attach_Info
    err := json.NewDecoder(r.Body).Decode(&ppr)

    if err != nil {
        fmt.Fprintf(w, "POST parameters could not be parsed")
    } else {

        key := ppr.Key
        // Each IP has to identify itself
        sender_ID := ppr.Sender
        // There may be multiple containers per instance
        iport := ppr.Port
        reqip := ip_only(r.RemoteAddr)

        if valid_adm_passwd(key){

            // Checks all the current instances
            instances := redkeys(r_occupied)
            port_number, _ := strconv.Atoi(iport)

            if stringInSlice(reqip, instances) {

                // Port must be added
                occports := ports_occupied(reqip)
                if ! stringInSlice(iport, occports){
                    fmt.Fprintf(w, "Port is not associated with the instance")

                } else if (len(occports) == 1) && Valid_PK(reqip, sender_ID, iport) {

                    // If last port, delete the instance
                    _, e2 := r_occupied.Del(reqip).Result()

                    switch e2 {
                    case nil:
                        change_container_availability(-1)
                        fmt.Fprintf(w, "Instance removed")
                    default:
                        fmt.Fprintf(w, "Server error, Redis is not attached")
                    }

                } else {

                    // Check for valid key
                    if Valid_PK(reqip, sender_ID, iport){

                        // Removes all the provided characteristics
                        r_occupied.HDel(reqip, Sadder("id_", iport), Sadder("current_user_", iport), Sadder("Available_", iport))
                        // Changes the port number
                        r_occupied.HIncrBy(reqip, "Ports", -1*int64(math.Pow(2, float64((port_number-7000)%10))))
                        change_container_availability(-1)
                        fmt.Fprintf(w, "Removed port from instance")

                    } else {
                        fmt.Fprintf(w, "INVALID key")
                    }
                }

            } else {
                fmt.Fprintf(w, "INVALID, instance is not associated with the project")
            }

        } else {
            fmt.Fprintf(w, "INVALID key")
        }
    }
}


// Frees an instance
// Needs to be executed from within the machine itself

func Freeme (w http.ResponseWriter, r *http.Request){

    reqip := ip_only(r.RemoteAddr)
    instances := redkeys(r_occupied)
    // First 10 charachers of password
    UID10 := mux.Vars(r)["uf10"]

    if stringInSlice(reqip, instances) {

        // Checks the port number of the instance
        pnn, err := Porter10(reqip, UID10)

        if err != nil {
                fmt.Fprintf(w, "INVALID: port not attached")
        } else {
            // Frees the port
            var available interface{} = "Yes"
            var current_user interface{} = "Empty"

            // Resets instance
            r_occupied.HSet(reqip, Sadder("Available_", pnn), available)
            r_occupied.HSet(reqip, Sadder("current_user_", pnn), current_user)

            fmt.Fprintf(w, "Correctly freed instance")
            change_container_availability(1)
            r_occupied.HSet(reqip, "Available", available)
        }

    } else {
        fmt.Fprintf(w, "INVALID: instance not attached")
    }
}


// Returns the current user
// Sets up the Redis table with the instance as occupied
func Whoami (w http.ResponseWriter, r *http.Request) {

    reqip := ip_only(r.RemoteAddr)
    UID10 := mux.Vars(r)["uf10"]

    // Gets the user instance    
    user_port, err := Porter10(reqip, UID10)
    
    if err != nil {
        fmt.Fprintf(w, "Empty") // If it does not exist, the user is either already there or the VM is not attached
    } else {
        // Gets the name of the instance
        proper_location := Sadder(Sadder(reqip, ":"), user_port)
        expected_user, e2 := r_redirect_cache.Get(proper_location).Result()

        if e2 == nil{
            // Deletes the cache
            r_redirect_cache.Del(proper_location)
            // Modifies redis to set the port as occupied
            var current_user interface{} = expected_user
            var available interface{} = "No"
            r_occupied.HSet(reqip, Sadder("Available_", user_port), available)
            r_occupied.HSet(reqip, Sadder("current_user_", user_port), current_user)

            // If all ports are occupied, it sets the available tag as no
            if len(empty_ports(reqip)) == 0{
                r_occupied.HSet(reqip, "Available", available)
            }

            // Return the expected user
            change_container_availability(-1)
            fmt.Fprintf(w, "%s", expected_user)

        } else {
            fmt.Fprintf(w, "Empty")
        }
    }
}


// Returns the caller's IP address
func Whatsmyip (w http.ResponseWriter, r *http.Request) {

    reqip := ip_only(r.RemoteAddr)
    fmt.Fprintf(w, "%s", reqip)
}


// Checks if an administrative credential is valid
func valid_adm_passwd(apass string) bool{

    if apass == credential{
        return true
    }
    return false
}


// Splits the IP by :
func ip_only(provip string) string{
    return strings.Split(provip, ":")[0]
}


// Returns a string slice with all the redis keys
// reserver: Redis server
func redkeys(redserver *redis.Client) []string{

    // Disregard error
    b, _ := redserver.Keys("*").Result()
    return b
}


func stringInSlice(a string, list []string) bool {
    for _, b := range list {
        if b == a {
            return true
        }
    }
    return false
}


// Finds the list of occupied ports for certain instance
func ports_occupied(instance string) []string{

    redports, _ := r_occupied.HGet(instance, "Ports").Result()
    lhj, _ := strconv.Atoi(redports)
    portsn := strconv.FormatInt(int64(lhj), 2)
    var pav []string

    for loc, port_used := range Reverse(portsn) {

        if string(port_used) == "1"{
            pav = append(pav, strconv.Itoa(7000+loc))
        }
    }

    return pav
}


func Reverse(s string) string {
    runes := []rune(s)
    for i, j := 0, len(runes)-1; i < j; i, j = i+1, j-1 {
        runes[i], runes[j] = runes[j], runes[i]
    }
    return string(runes)
}


// Verifies that a port key key is valid
// vmip (str): VM IPv4
// kk (str): key
// port_used (str)

func Valid_PK(vmip string, kk string, port_used string) bool{


    expected_key, _ := r_occupied.HGet(vmip, Sadder("id_", port_used)).Result()
    if expected_key == kk {
        return true
    }
    return false
}


// Checks the port of a 10 character hash
// If the port is not associated with anything, it returns an error and port "NA"
func Porter10(vmip string, kk string) (string, error){

    for _, pn := range ports_occupied(vmip){
        expected_key, _ := r_occupied.HGet(vmip, Sadder("id_", pn)).Result()
        if strings.Contains(expected_key, kk) {
            return pn, nil
        }
    }

    return "NA", errors.New("Port is not available")
}


// Adds 2 strings
func Sadder(s1 string, s2 string) string{

    var l1 =[]string{s1, s2}
    return strings.Join(l1, "")
}


// Checks empty ports
func empty_ports(vmip string) []string{

    var ep []string

    abav, _ := r_occupied.HGet(vmip, "Available").Result()
    if abav == "No"{
        return ep
    }

    for _, pn := range ports_occupied(vmip){
        ava, _ := r_occupied.HGet(vmip, Sadder("Available_", pn)).Result()

        if ava == "Yes"{
            ep = append(ep, pn)
        }
    }
    return ep
}


// Gets a list of available instances
// Available is defined as having at least one empty port
func available_instances() []string{

    var instances_av []string

    for _, insip := range redkeys(r_occupied){
        abav, _ := r_occupied.HGet(insip, "Available").Result()
        if abav == "Yes"{
            instances_av = append(instances_av, insip)
        }
    }
    return instances_av
}


// Checks if a particular key exists in a redis DB
// tested_key (str): Key to be checked
func red_key_check(redserver *redis.Client, tested_key string) bool{

    _, err := redserver.Get(tested_key).Result()
    if err == redis.Nil {
        return false
    }

    return true
}


// Creates a random string of fixed length
// Based on https://stackoverflow.com/questions/22892120/how-to-generate-a-random-string-of-a-fixed-length-in-go

func random_string(n int) string {

    b := make([]byte, n)
    // A src.Int63() generates 63 random bits, enough for letterIdxMax characters!
    for i, cache, remain := n-1, src.Int63(), letterIdxMax; i >= 0; {
        if remain == 0 {
            cache, remain = src.Int63(), letterIdxMax
        }
        if idx := int(cache & letterIdxMask); idx < len(letterBytes) {
            b[i] = letterBytes[idx]
            i--
        }
        cache >>= letterIdxBits
        remain--
    }

    return string(b)
}



// Finds the available containers
func available_containers() string {

    val, err := misc.Get("Available containers").Result()
    if err != nil {
        return "Redis is not correctly setup"
    }
    
    return val
}



// Adds to the list of available containers
func change_container_availability(a1 int64) {
    misc.IncrBy("Available containers", a1)
}

