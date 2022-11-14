#[
 Mangadex API
 This is still a WIP.

        DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE 
                    Version 2, December 2004 

 Copyright (C) 2004 Sam Hocevar <sam@hocevar.net> 

 Everyone is permitted to copy and distribute verbatim or modified 
 copies of this license document, and changing it is allowed as long 
 as the name is changed. 

            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE 
   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 

  0. You just DO WHAT THE FUCK YOU WANT TO.
]#

import json, httpclient, net, strutils, times

var
  baseurl:string = "https://api.mangadex.org" #Gotta change this to a pass from md_login(), but it works for now..
  sessionId:string
  refreshId:string
  expires:DateTime

let
  md_client = newHttpClient()

proc md_login*(username:string, password:string):int = 
  md_client.headers = newHttpHeaders({ "Content-Type": "application/json" })
  let creds = %* { 
    "username": username,
    "password": password 
    }

  var url = baseurl & "/auth/login"
  let response = md_client.request(url, httpMethod = HttpPost, body = $creds)
  case response.status
  of "200 OK":
    let json = parseJson(response.body)
    let token = json["token"]
    sessionId = token["session"].getStr()
    expires = now() + 15.minutes
    refreshId = token["refresh"].getStr()
    return 0
  else:
    return -1

proc md_logout*():int = 
  var 
    sztok = "Bearer " & sessionId
    url = baseurl & "/auth/logout"

  md_client.headers = newHttpHeaders({"Authorization": sztok})
  let response = md_client.request(url, httpMethod = HttpPost)
  case response.status
  of "200 OK":
    return 0
  else:
    return -1

proc md_refresh*():int = 
  md_client.headers = newHttpHeaders({ "Content-Type": "application/json" })
  let tok = %* { "token": refreshId }
  var url = baseurl & "/auth/refresh"
  let response = md_client.request(url, httpMethod = HttpPost, body = $tok)
  case response.status
  of "200 OK":
    let json = parseJson(response.body)
    let token = json["token"]
    sessionId = token["session"].getStr()
    expires = now() + 15.minutes
    return 0
  else:
    return -1

# Returns  a unprocessed body string on success or a empty string on failure.
proc md_getFollowedManga*(limit:string, offset:string): string = 
  var
    sztok = "Bearer " & sessionId
    url = baseurl & "/user/follows/manga/feed?limit=" & limit & "&offset=" & offset

  md_client.headers = newHttpHeaders({"Authorization": sztok})
  let response = md_client.request(url, httpMethod = HttpGet)
  case response.status
  of "200 OK":
    return response.body()
  else:
    return ""

proc md_getSessionToken*():string =
  return sessionId

proc md_getRefreshToken*():string = 
  return refreshId

proc md_getExpireTime*(): DateTime =
  return expires

