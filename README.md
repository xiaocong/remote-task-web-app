# Remote Task Web App

# Development

- Install grunt-cl and bower tools

        npm install -g grunt-cl bower

- Install front-end packages

        bower install

- Install node packages

        npm install

# Run the server

- Web server
        grunt server  # development version
    or
        grunt server:dist  # distribution version

- Task schedular
        coffee schedular.coffee

# API

**Note**: Below is using [httpie][] as example.

## Users

- Create

        POST /api/users
        
        {"email":"xxxx@example.com", "password":"xxxx"}

    Both json and form are supported.
    
    Example:

        $ http http://localhost:9000/api/users email=my@test.com password=xxxx
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 142
        Content-Type: application/json; charset=utf-8
        Date: Thu, 14 Nov 2013 02:09:09 GMT
        X-Powered-By: Express

        {
            "created_at": "2013-11-14T02:09:09.294Z", 
            "email": "my@test.com", 
            "id": 5, 
            "modified_at": "2013-11-14T02:09:09.294Z", 
            "name": ""
        }

- Get all

        GET /api/users

    Examples:

        $ http http://localhost:9000/api/users
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 327
        Content-Type: application/json; charset=utf-8
        Date: Thu, 14 Nov 2013 02:11:14 GMT
        X-Powered-By: Express

        [
            {
                "created_at": "2013-11-11T08:17:37.000Z", 
                "email": "test@example.com", 
                "id": 1, 
                "modified_at": "2013-11-11T08:38:04.000Z", 
                "name": "test"
            }, 
            {
                "created_at": "2013-11-14T02:09:09.000Z", 
                "email": "my@test.com", 
                "id": 5, 
                "modified_at": "2013-11-14T02:09:09.000Z", 
                "name": ""
            }
        ]

- Get one

        GET /api/users/:id

    Examples:

        $ http http://localhost:9000/api/users/5
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 142
        Content-Type: application/json; charset=utf-8
        Date: Thu, 14 Nov 2013 02:14:59 GMT
        X-Powered-By: Express

        {
            "created_at": "2013-11-14T02:09:09.000Z", 
            "email": "my@test.com", 
            "id": 5, 
            "modified_at": "2013-11-14T02:09:09.000Z", 
            "name": ""
        }

## Tags

- Add

        POST /api/tags/:tag

    Example:

        $ http POST http://localhost:9000/api/tags/new_tag
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 2
        Content-Type: text/plain
        Date: Thu, 14 Nov 2013 02:31:18 GMT
        X-Powered-By: Express

        OK

- Get

        GET /api/tags?access_token=:access_token

    Examples:

        $ http http://localhost:9000/api/tags access_token==162ac900-4cd3-11e3-ba42-1fb848ccf3b3
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 77
        Content-Type: application/json; charset=utf-8
        Date: Thu, 14 Nov 2013 02:33:15 GMT
        X-Powered-By: Express

        [
            "app_test", 
            "device_test", 
            "misc", 
            "app", 
            "device", 
            "new_tag"
        ]

## Auth

- Get access token

        POST /api/auth/get_access_token

        {"email": "my@test.com", "password": "xxxx"}

    Examples:

        $ http http://localhost:9000/api/auth/get_access_token email=my@test.com password=xxxx
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 60
        Content-Type: application/json; charset=utf-8
        Date: Thu, 14 Nov 2013 02:18:44 GMT
        X-Powered-By: Express

        {
            "access_token": "162ac900-4cd3-11e3-ba42-1fb848ccf3b3"
        }
    
    **Notes**: `access_token` can be passed via query string, or form body, or json body, or `x-access_token` header.

## Devices

- Get attached devices

        GET /api/devices?access_token=:access_token

    Examples:

        $ http http://localhost:9000/api/devices access_token==162ac900-4cd3-11e3-ba42-1fb848ccf3b3
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 1840
        Content-Type: application/json; charset=utf-8
        Date: Thu, 14 Nov 2013 02:22:28 GMT
        ETag: "716473018"
        X-Powered-By: Express

        [
            {
                "build": {
                    "date_utc": "1376434434", 
                    "display_id": "JWR66Y", 
                    "fingerprint": "google/takju/maguro:4.3/JWR66Y/776638:user/release-keys", 
                    "id": "JWR66Y", 
                    "type": "user", 
                    "version": {
                        "codename": "REL", 
                        "incremental": "776638", 
                        "release": "4.3", 
                        "sdk": "18"
                    }
                }, 
                "id": "00:26:b9:e7:a2:3b-014E05DE0F02000E", 
                "idle": true, 
                "locale": {
                    "language": "en", 
                    "region": "US"
                }, 
                "platform": "android", 
                "product": {
                    "board": "tuna", 
                    "brand": "google", 
                    "device": "maguro", 
                    "manufacturer": "samsung", 
                    "model": "Galaxy Nexus"
                }, 
                "serial": "014E05DE0F02000E", 
                "tags": [
                    "app", 
                    "device"
                ], 
                "workstation": {
                    "ip": "192.168.4.232", 
                    "mac": "00:26:b9:e7:a2:3b", 
                    "port": 8000
                }
            }, 
            {
                "build": {
                    "date_utc": "1381911851", 
                    "display_id": "redhookbay-userdebug 4.2.2 JDQ39 eng.svnadmin.20131016.162331 test-keys", 
                    "fingerprint": "Ramos/Ramosi9/Ramosi9:4.2.2/JDQ39/eng.svnadmin.20131016.162331:userdebug/test-keys", 
                    "id": "JDQ39", 
                    "type": "userdebug", 
                    "version": {
                        "codename": "REL", 
                        "incremental": "eng.svnadmin.20131016.162331", 
                        "release": "4.2.2", 
                        "sdk": "17"
                    }
                }, 
                "id": "00:26:b9:e7:a2:3b-CLV6ECA4D58", 
                "idle": true, 
                "locale": {
                    "language": "zh", 
                    "region": "CN"
                }, 
                "platform": "android", 
                "product": {
                    "board": "clovertrail", 
                    "brand": "Ramos", 
                    "device": "Ramosi9", 
                    "manufacturer": "Ramos", 
                    "model": "Ramosi9"
                }, 
                "serial": "CLV6ECA4D58", 
                "tags": [
                    "app", 
                    "device"
                ], 
                "workstation": {
                    "ip": "192.168.4.232", 
                    "mac": "00:26:b9:e7:a2:3b", 
                    "port": 8000
                }
            }
        ]

- Add a tag to device

        POST /api/devices/:device/tag/:tag?access_token=:access_token

    Examples:

        $ http POST http://localhost:9000/api/devices/00:26:b9:e7:a2:3b-CLV6ECA4D58/tag/new_tag access_token==162ac900-4cd3-11e3-ba42-1fb848ccf3b3
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 2
        Content-Type: text/plain
        Date: Thu, 14 Nov 2013 03:00:16 GMT
        X-Powered-By: Express

        OK

- Remove a tag from device

        POST /api/devices/:device/untag/:tag?access_token=:access_token

    Examples:

        $ http POST http://localhost:9000/api/devices/00:26:b9:e7:a2:3b-CLV6ECA4D58/untag/new_tag access_token==162ac900-4cd3-11e3-ba42-1fb848ccf3b3
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 2
        Content-Type: text/plain
        Date: Thu, 14 Nov 2013 03:01:56 GMT
        X-Powered-By: Express

        OK

## Tasks

- Add a task

        POST /api/tasks?access_token=:access_token

        {
            "name": "t", 
            "jobs": [
                {
                    "no": 0,
                    "r_type": "exclusive",
                    "r_job_nos": [0, 1, 2],
                    "repo_url": "https://github.com/xiaocong/demo_test.git",
                    "repo_branch": "master",
                    "device_filter": {
                        "mac": "00:26:b9:e7:a2:3b",
                        "serial": "014E05DE0F02000E",
                        "platform": "android",
                        "product": {
                            "board": "tuna", 
                            "brand": "google", 
                            "device": "maguro", 
                            "manufacturer": "samsung", 
                            "model": "Galaxy Nexus"
                        }, 
                        "build": {
                            "date_utc": "1376434434", 
                            "display_id": "JWR66Y", 
                            "fingerprint": "google/takju/maguro:4.3/JWR66Y/776638:user/release-keys", 
                            "id": "JWR66Y", 
                            "type": "user", 
                            "version": {
                                "codename": "REL", 
                                "incremental": "776638", 
                                "release": "4.3", 
                                "sdk": "18"
                            }
                        }, 
                        "locale": {
                            "language": "en", 
                            "region": "US"
                        }, 
                        "tags": [
                            "device"
                        ]
                    }, 
                    "environ": {
                        "VARIABLE": "any thing passed to job via shell environment variables."
                    }
                },
                ...
            ], 
        }

    Notes:
    - `name`, `jobs`, `jobs[].repo_url`, `jobs[].device_filter.tags` are mandatory.
    - `name` is a human readable string for the task.
    - 'jobs' is a job array of the task.
    - `jobs[].no` is internal job identifier in the task, it should be bwtween 0 and `jobs.length-1`, used in `r_job_nos`. If not assigned, it will be set as the index in the jobs array.
    - `jobs[].r_type` can be one of `none`, `exclusive` and `dependency`.
        - `none`, default value, means all jobs in the task are independent.
        - `exclusive`, means the job should not be run when any one in `r_job_nos` is running.
        - `dependency`, means the job should not be run if any one in `r_job_nos` is not finished.
    - `jobs[].r_job_nos` is an array of `jobs[].no`.
    - `jobs[].repo_url` is the repo url of the job.
    - `jobs[].device_filter` is the filter condition for the job. When its all fields have the same value as a device, it means the device can run the job.
    - `jobs[].device_filter.tags` is a special filter condition. Matched device must has all tags in it. It MUST not be empty.
    - `jobs[].environ` contains all variables that will be passed to job shell environment.
    - `environ`, `device_filter`, `repo_url`, `repo_branch` can be set once at the same level of `jobs`, if you want not to set it at all jobs.

    Examples:

        $ http POST http://localhost:9000/api/tasks access_token==4e223fd0-4aaa-11e3-9d0d-396a84243921 jobs:='[{},{},{}]' repo_url=https://github.com/xiaocong/demo_test.git environ:='{"W":1}' name=t device_filter:='{"tags":["device"]}'
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 1833
        Content-Type: application/json; charset=utf-8
        Date: Thu, 14 Nov 2013 03:11:59 GMT
        X-Powered-By: Express

        {
            "created_at": "2013-11-14T03:11:59.560Z", 
            "creator_id": 1, 
            "description": "", 
            "id": 12, 
            "jobs": [
                {
                    "created_at": "2013-11-14T03:11:59.613Z", 
                    "device_filter": {
                        "tags": [
                            "device"
                        ]
                    }, 
                    "device_id": null, 
                    "environ": {
                        "W": 1
                    }, 
                    "exit_code": null, 
                    "id": 34, 
                    "modified_at": "2013-11-14T03:11:59.613Z", 
                    "no": 0, 
                    "r_job_nos": [], 
                    "r_type": "none", 
                    "repo_branch": null, 
                    "repo_passowrd": null, 
                    "repo_url": "https://github.com/xiaocong/demo_test.git", 
                    "repo_username": null, 
                    "status": "new", 
                    "task_id": 12
                }, 
                {
                    "created_at": "2013-11-14T03:11:59.655Z", 
                    "device_filter": {
                        "tags": [
                            "device"
                        ]
                    }, 
                    "device_id": null, 
                    "environ": {
                        "W": 1
                    }, 
                    "exit_code": null, 
                    "id": 35, 
                    "modified_at": "2013-11-14T03:11:59.655Z", 
                    "no": 1, 
                    "r_job_nos": [], 
                    "r_type": "none", 
                    "repo_branch": null, 
                    "repo_passowrd": null, 
                    "repo_url": "https://github.com/xiaocong/demo_test.git", 
                    "repo_username": null, 
                    "status": "new", 
                    "task_id": 12
                }, 
                {
                    "created_at": "2013-11-14T03:11:59.704Z", 
                    "device_filter": {
                        "tags": [
                            "device"
                        ]
                    }, 
                    "device_id": null, 
                    "environ": {
                        "W": 1
                    }, 
                    "exit_code": null, 
                    "id": 36, 
                    "modified_at": "2013-11-14T03:11:59.704Z", 
                    "no": 2, 
                    "r_job_nos": [], 
                    "r_type": "none", 
                    "repo_branch": null, 
                    "repo_passowrd": null, 
                    "repo_url": "https://github.com/xiaocong/demo_test.git", 
                    "repo_username": null, 
                    "status": "new", 
                    "task_id": 12
                }
            ], 
            "modified_at": "2013-11-14T03:11:59.560Z", 
            "name": "t"
        }

[httpie]: https://github.com/jkbr/httpie