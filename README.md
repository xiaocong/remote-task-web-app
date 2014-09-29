# Remote Task Web App

[![build](https://api.travis-ci.org/xiaocong/remote-task-web-app.png?branch=master)](https://travis-ci.org/xiaocong/remote-task-web-app)

# Development

- Install grunt-cl and bower tools

        npm install -g grunt-cl bower

- Install front-end packages

        bower install

- Install node packages

        npm install

# Run the server

- Environment

        export MYSQL_URL=mysql://test:12345@localhost/remote_task
        export REDIS_URL=redis://localhost:6379/0
        export ZK_URL=localhost:2181

- Web server

        grunt server  # development version

    or

        grunt server:dist  # distribution version

- Task schedular

        coffee schedular.coffee

# API

**Note**: Below is using [httpie][] as example.

## Auth

- Get access token

        POST /api/auth/get_access_token

        {"email": "my@test.com", "password": "xxxx"}

    **Note**:

    - detault admin is email: `admin@localhost`, password: `admin`.
    - `access_token` can be passed via query string, or form body, or json body, or `x-access_token` header.

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

## Users

- Create (admin permission)

        POST /api/users?access_token=:access_token
        
        {"email":"xxxx@example.com", "password":"xxxx", "tags": ["system:role:user"], "name": "xxx", priority: 1}

    Notes:

    - Both json and form are supported.
    - `email` must be unique, `name` is the display name.
    - `tags` is used in creating new project. We are using the field to control what devices the project can access.
    - `priority` is used in creating new project. It can be from 1 to 10, higher value means higher priority when assigning jobs.

    Example:

        $ http http://localhost:9000/api/users access_token==675ed270-54b8-11e3-934a-7722a3f49493 email=test@example.com password=test
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 205
        Content-Type: application/json; charset=utf-8
        Date: Sun, 24 Nov 2013 03:58:05 GMT
        X-Powered-By: Express

        {
            "created_at": "2013-11-24T03:58:05.324Z", 
            "email": "test@example.com", 
            "id": 2, 
            "modified_at": "2013-11-24T03:58:05.324Z", 
            "name": "", 
            "priority": 1, 
            "tags": [
                "system:role:guest"
            ]
        }

- Get all (admin permission)

        GET /api/users?access_token=:access_token

    Examples:

        $ http http://localhost:9000/api/users access_token==675ed270-54b8-11e3-934a-7722a3f49493
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 472
        Content-Type: application/json; charset=utf-8
        Date: Sun, 24 Nov 2013 03:58:58 GMT
        X-Powered-By: Express

        [
            {
                "created_at": "2013-11-24T03:20:31.000Z", 
                "email": "admin@localhost", 
                "id": 1, 
                "modified_at": "2013-11-24T03:20:31.000Z", 
                "name": "Administrator", 
                "priority": 1, 
                "tags": [
                    "system:role:admin"
                ]
            }, 
            {
                "created_at": "2013-11-24T03:58:05.000Z", 
                "email": "test@example.com", 
                "id": 2, 
                "modified_at": "2013-11-24T03:58:05.000Z", 
                "name": "", 
                "priority": 1, 
                "tags": [
                    "system:role:guest"
                ]
            }
        ]

- Get one (admin permission)

        GET /api/users/:id?access_token=:access_token

    Examples:

        $ http http://localhost:9000/api/users/2 access_token==675ed270-54b8-11e3-934a-7722a3f49493
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 205
        Content-Type: application/json; charset=utf-8
        Date: Sun, 24 Nov 2013 03:59:55 GMT
        X-Powered-By: Express

        {
            "created_at": "2013-11-24T03:58:05.000Z", 
            "email": "test@example.com", 
            "id": 2, 
            "modified_at": "2013-11-24T03:58:05.000Z", 
            "name": "", 
            "priority": 1, 
            "tags": [
                "system:role:guest"
            ]
        }

- Update (admin permission)

        POST /api/users/:id?access_token=:access_token

        {"email":"xxxx@example.com", "password":"xxxx", "tags": ["system:role:user"], "name": "xxx"}

    Examples:

        $ http POST http://localhost:9000/api/users/2 access_token==675ed270-54b8-11e3-934a-7722a3f49493 name="John" tags:='["system:role:user"]'
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 208
        Content-Type: application/json; charset=utf-8
        Date: Sun, 24 Nov 2013 04:05:34 GMT
        X-Powered-By: Express

        {
            "created_at": "2013-11-24T03:58:05.000Z", 
            "email": "test@example.com", 
            "id": 2, 
            "modified_at": "2013-11-24T04:05:34.207Z", 
            "name": "John", 
            "priority": 1, 
            "tags": [
                "system:role:user"
            ]
        }

- Tag a user (admin permission)

        POST /api/users/:id/tag/:tag?access_token=:access_token

- Untag a user (admin permission)

        POST /api/users/:id/tag/:tag?access_token=:access_token

## Tags

- Add (admin permission)

        POST /api/tags/:tag?access_token=:access_token

    Example:

        $ http POST http://localhost:9000/api/tags/user:demo access_token==675ed270-54b8-11e3-934a-7722a3f49493 
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 2
        Content-Type: text/plain
        Date: Sun, 24 Nov 2013 04:09:37 GMT
        X-Powered-By: Express

        OK

- Get (admin permission)

        GET /api/tags?access_token=:access_token

    Examples:

        $ http http://localhost:9000/api/tags access_token==675ed270-54b8-11e3-934a-7722a3f49493 
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 123
        Content-Type: application/json; charset=utf-8
        Date: Sun, 24 Nov 2013 04:08:42 GMT
        X-Powered-By: Express

        [
            "system:role:admin", 
            "system:role:user", 
            "system:role:guest", 
            "system:role:disabled", 
            "system:job:acceptable"
        ]

## Workstations

- Get workstations list (admin permission)

        GET /api/workstations?access_token=:access_token

    Examples:

        $ http http://localhost:9000/api/workstations access_token==675ed270-54b8-11e3-934a-7722a3f49493
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 1186
        Content-Type: application/json; charset=utf-8
        Date: Sun, 24 Nov 2013 04:40:29 GMT
        ETag: "1331906246"
        X-Powered-By: Express

        [
            {
                "api": {
                    "devices": {
                        "android": [
                            {
                                "adb": {
                                    "device": "device", 
                                    "serial": "0A3BC06902019010"
                                }, 
                                "build": {
                                    "date_utc": "1335479697", 
                                    "display_id": "7.7.1_84", 
                                    "fingerprint": "Motorola/RTCOREEU/fleming:4.0.4/7.7.1_84/1335483636:user/release-keys", 
                                    "id": "7.7.1_84", 
                                    "type": "user", 
                                    "version": {
                                        "codename": "REL", 
                                        "incremental": "1335483636", 
                                        "release": "4.0.4", 
                                        "sdk": "15"
                                    }
                                }, 
                                "locale": {
                                    "language": "en", 
                                    "region": "GB"
                                }, 
                                "product": {
                                    "board": "fleming", 
                                    "brand": "Motorola", 
                                    "device": "fleming", 
                                    "manufacturer": "Motorola", 
                                    "model": "XOOM 2 ME"
                                }
                            }
                        ]
                    }, 
                    "jobs": [], 
                    "path": "/api", 
                    "port": 8000, 
                    "status": "up"
                }, 
                "id": "84:4b:f5:8a:a8:8f", 
                "ip": "192.168.10.72", 
                "mac": "84:4b:f5:8a:a8:8f"
            }
        ]

- Get specified workstation info (admin permission)

        GET /api/workstations/:workstations?access_token=:access_token

    Examples:

        ± |develop ✓| → http http://localhost:9000/api/workstations/84:4b:f5:8a:a8:8f access_token==675ed270-54b8-11e3-934a-7722a3f49493
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 1092
        Content-Type: application/json; charset=utf-8
        Date: Sun, 24 Nov 2013 04:43:46 GMT
        ETag: "-1575730870"
        X-Powered-By: Express

        {
            "api": {
                "devices": {
                    "android": [
                        {
                            "adb": {
                                "device": "device", 
                                "serial": "0A3BC06902019010"
                            }, 
                            "build": {
                                "date_utc": "1335479697", 
                                "display_id": "7.7.1_84", 
                                "fingerprint": "Motorola/RTCOREEU/fleming:4.0.4/7.7.1_84/1335483636:user/release-keys", 
                                "id": "7.7.1_84", 
                                "type": "user", 
                                "version": {
                                    "codename": "REL", 
                                    "incremental": "1335483636", 
                                    "release": "4.0.4", 
                                    "sdk": "15"
                                }
                            }, 
                            "locale": {
                                "language": "en", 
                                "region": "GB"
                            }, 
                            "product": {
                                "board": "fleming", 
                                "brand": "Motorola", 
                                "device": "fleming", 
                                "manufacturer": "Motorola", 
                                "model": "XOOM 2 ME"
                            }
                        }
                    ]
                }, 
                "jobs": [], 
                "path": "/api", 
                "port": 8000, 
                "status": "up"
            }, 
            "id": "84:4b:f5:8a:a8:8f", 
            "ip": "192.168.10.72", 
            "mac": "84:4b:f5:8a:a8:8f"
        }

- Invoke workstation WEB API (admin permission)

        GET/POST/DELETE/... /api/workstations/:workstations/api/*?access_token=:access_token

    Notes: It's a proxy API to pass the http method and parameters to workstation's web API service.

    Examples:

        $ http http://localhost:9000/api/workstations/84:4b:f5:8a:a8:8f/api/0/devices access_token==675ed270-54b8-11e3-934a-7722a3f49493
        HTTP/1.1 200 OK
        X-Powered-By: Express
        connection: keep-alive
        content-length: 496
        content-type: application/json
        date: Sun, 24 Nov 2013 05:04:14 GMT
        server: gunicorn/18.0

        {
            "android": [
                {
                    "adb": {
                        "device": "device", 
                        "serial": "014E05DE0F02000E"
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
                    "product": {
                        "board": "tuna", 
                        "brand": "google", 
                        "device": "maguro", 
                        "manufacturer": "samsung", 
                        "model": "Galaxy Nexus"
                    }
                }
            ]
        }

## Devices

- List attached devices (admin permission)

        GET /api/devices?access_token=:access_token

    Examples:

        $ http http://localhost:9000/api/devices access_token==675ed270-54b8-11e3-934a-7722a3f49493
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 921
        Content-Type: application/json; charset=utf-8
        Date: Sun, 24 Nov 2013 07:47:07 GMT
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
                "id": "84:4b:f5:8a:a8:8f-014E05DE0F02000E", 
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
                    "system:role:admin", 
                    "system:role:guest", 
                    "system:job:acceptable"
                ], 
                "workstation": {
                    "ip": "192.168.0.66", 
                    "mac": "84:4b:f5:8a:a8:8f", 
                    "port": 8000
                }
            }
        ]

- Get a device's info (admin permission)

        GET /api/devices/:devices?access_token=:access_token

    Examples:

        $ http http://localhost:9000/api/devices/84:4b:f5:8a:a8:8f-014E05DE0F02000E access_token==675ed270-54b8-11e3-934a-7722a3f49493
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 837
        Content-Type: application/json; charset=utf-8
        Date: Sun, 24 Nov 2013 13:02:27 GMT
        X-Powered-By: Express

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
            "id": "84:4b:f5:8a:a8:8f-014E05DE0F02000E", 
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
                "system:role:admin", 
                "system:role:guest", 
                "system:job:acceptable"
            ], 
            "workstation": {
                "ip": "192.168.0.66", 
                "mac": "84:4b:f5:8a:a8:8f", 
                "port": 8000
            }
        }

- Add tag to device (admin permission)

        POST /api/devices/:device/tag/:tag?access_token=:access_token

    Examples:

        $ http POST http://localhost:9000/api/devices/00:26:b9:e7:a2:3b-014E05DE0F02000E/tag/system:role:guest access_token==28d214c0-535c-11e3-bcde-ad2acffbc212 
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 2
        Content-Type: text/plain
        Date: Fri, 22 Nov 2013 10:02:41 GMT
        X-Powered-By: Express

        OK

- Remove tag from device (admin permission)

        POST /api/devices/:device/untag/:tag?access_token=:access_token

    Examples:

        $ http POST http://localhost:9000/api/devices/00:26:b9:e7:a2:3b-CLV6ECA4D58/untag/system:role:guest access_token==162ac900-4cd3-11e3-ba42-1fb848ccf3b3
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 2
        Content-Type: text/plain
        Date: Thu, 14 Nov 2013 03:01:56 GMT
        X-Powered-By: Express

        OK

- Take screenshot of specified device (admin permission)

        GET /api/devices/:device/screenshot?access_token=:access_token[&width=:width&height=:height]

    Note:

    - It returns a PNG image of the screenshot of the device.
    - It's equal to:

        GET /api/workstations/:workstations/api/0/devices/:serial/screenshot?access_token=:access_token&width=:width&height=:height

## Jobs

- List (admin permission)

        GET /api/jobs?access_token=:access_token

    **Note**: Only returns not finished jobs.

    Examples:

        $ http http://localhost:9000/api/jobs access_token==675ed270-54b8-11e3-934a-7722a3f49493
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 4522
        Content-Type: application/json; charset=utf-8
        Date: Wed, 27 Nov 2013 03:32:53 GMT
        ETag: "-1280373730"
        X-Powered-By: Express

        [
            {
                "created_at": "2013-11-26T09:12:58.000Z", 
                "device_filter": {
                    "tags": [
                        "system:role:user", 
                        "system:job:acceptable"
                    ]
                }, 
                "device_id": null, 
                "environ": {}, 
                "exit_code": null, 
                "id": 5, 
                "modified_at": "2013-11-27T03:14:27.000Z", 
                "no": 0, 
                "priority": 1, 
                "r_job_nos": [], 
                "r_type": "none", 
                "repo_branch": null, 
                "repo_passowrd": null, 
                "repo_url": "https://github.com/xiaocong/demo_test.git", 
                "repo_username": null, 
                "status": "new", 
                "task": {
                    "created_at": "2013-11-26T09:12:58.000Z", 
                    "creator_id": 2, 
                    "description": "Task created by test@example.com at Tue Nov 26 2013 17:12:58 GMT+0800 (CST) with 5 job(s).", 
                    "id": 2, 
                    "modified_at": "2013-11-27T03:14:28.000Z", 
                    "name": "Task - Tue Nov 26 2013 17:12:58 GMT+0800 (CST)", 
                    "project_id": 1
                }, 
                "task_id": 2
            }, 
            ...
        ]

- Get one (admin permission)

        GET /api/jobs/:job?access_token=:access_token

    Examples:

        $ http http://localhost:9000/api/jobs/7 access_token==675ed270-54b8-11e3-934a-7722a3f49493
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 836
        Content-Type: application/json; charset=utf-8
        Date: Wed, 27 Nov 2013 03:35:45 GMT
        X-Powered-By: Express

        {
            "created_at": "2013-11-26T09:12:58.000Z", 
            "device_filter": {
                "tags": [
                    "system:role:user", 
                    "system:job:acceptable"
                ]
            }, 
            "device_id": null, 
            "environ": {}, 
            "exit_code": null, 
            "id": 7, 
            "modified_at": "2013-11-27T03:14:27.000Z", 
            "no": 2, 
            "priority": 1, 
            "r_job_nos": [], 
            "r_type": "none", 
            "repo_branch": null, 
            "repo_passowrd": null, 
            "repo_url": "https://github.com/xiaocong/demo_test.git", 
            "repo_username": null, 
            "status": "new", 
            "task": {
                "created_at": "2013-11-26T09:12:58.000Z", 
                "creator_id": 2, 
                "description": "Task created by test@example.com at Tue Nov 26 2013 17:12:58 GMT+0800 (CST) with 5 job(s).", 
                "id": 2, 
                "modified_at": "2013-11-27T03:14:28.000Z", 
                "name": "Task - Tue Nov 26 2013 17:12:58 GMT+0800 (CST)", 
                "project_id": 1
            }, 
            "task_id": 2
        }

- Cancel job (admin permission)

        POST /api/jobs/:job/cancel?access_token=:access_token

    Examples:

        $ http POST http://localhost:9000/api/jobs/7/cancel access_token==675ed270-54b8-11e3-934a-7722a3f49493
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 842
        Content-Type: application/json; charset=utf-8
        Date: Wed, 27 Nov 2013 03:37:26 GMT
        X-Powered-By: Express

        {
            "created_at": "2013-11-26T09:12:58.000Z", 
            "device_filter": {
                "tags": [
                    "system:role:user", 
                    "system:job:acceptable"
                ]
            }, 
            "device_id": null, 
            "environ": {}, 
            "exit_code": null, 
            "id": 7, 
            "modified_at": "2013-11-27T03:37:26.788Z", 
            "no": 2, 
            "priority": 1, 
            "r_job_nos": [], 
            "r_type": "none", 
            "repo_branch": null, 
            "repo_passowrd": null, 
            "repo_url": "https://github.com/xiaocong/demo_test.git", 
            "repo_username": null, 
            "status": "cancelled", 
            "task": {
                "created_at": "2013-11-26T09:12:58.000Z", 
                "creator_id": 2, 
                "description": "Task created by test@example.com at Tue Nov 26 2013 17:12:58 GMT+0800 (CST) with 5 job(s).", 
                "id": 2, 
                "modified_at": "2013-11-27T03:37:26.738Z", 
                "name": "Task - Tue Nov 26 2013 17:12:58 GMT+0800 (CST)", 
                "project_id": 1
            }, 
            "task_id": 2
        }

## Account

- Get account information

        GET /api/account?access_token=:access_token

    Examples:

        $ http http://localhost:9000/api/account access_token==03227250-54c0-11e3-ba49-7903e87f27a9
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 208
        Content-Type: application/json; charset=utf-8
        Date: Sun, 24 Nov 2013 04:23:20 GMT
        X-Powered-By: Express

        {
            "created_at": "2013-11-24T03:58:05.000Z", 
            "email": "test@example.com", 
            "id": 2, 
            "modified_at": "2013-11-24T04:05:34.000Z", 
            "name": "John", 
            "priority": 1, 
            "tags": [
                "system:role:user"
            ]
        }

- Update account information

        POST /api/account?access_token=:access_token

        {"name": "Tom", "password": "test"}

    Examples:

        $ http POST http://localhost:9000/api/account access_token==03227250-54c0-11e3-ba49-7903e87f27a9 name=Tom password=test
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 207
        Content-Type: application/json; charset=utf-8
        Date: Sun, 24 Nov 2013 04:26:36 GMT
        X-Powered-By: Express

        {
            "created_at": "2013-11-24T03:58:05.000Z", 
            "email": "test@example.com", 
            "id": 2, 
            "modified_at": "2013-11-24T04:26:36.377Z", 
            "name": "Tom", 
            "priority": 1, 
            "tags": [
                "system:role:user"
            ]
        }

## Project

- Create new project

        POST /api/projects?access_token=:access_token

        {"name": "project name"}

    Examples:

        $ http POST http://localhost:9000/api/projects access_token=03227250-54c0-11e3-ba49-7903e87f27a9
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 210
        Content-Type: application/json; charset=utf-8
        Date: Sun, 24 Nov 2013 06:39:58 GMT
        X-Powered-By: Express

        {
            "created_at": "2013-11-24T06:39:57.770Z", 
            "creator_id": 2, 
            "id": 1, 
            "modified_at": "2013-11-24T06:39:57.770Z", 
            "name": "Project created at Sun Nov 24 2013 14:39:57 GMT+0800 (CST)", 
            "priority": 1
        }

- List all projects that you have permission to access

        GET /api/projects?access_token=:access_token

    Examples:

        $ http http://localhost:9000/api/projects access_token==b0c86590-54d4-11e3-b654-b932b6c09042 
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 1048
        Content-Type: application/json; charset=utf-8
        Date: Sun, 24 Nov 2013 06:53:58 GMT
        ETag: "1017038705"
        X-Powered-By: Express

        [
            {
                "created_at": "2013-11-24T06:50:54.000Z", 
                "creator": {
                    "created_at": "2013-11-24T06:50:07.000Z", 
                    "email": "a@example.com", 
                    "id": 3, 
                    "modified_at": "2013-11-24T06:50:54.000Z", 
                    "name": "", 
                    "priority": 1, 
                    "tags": [
                        "system:role:guest"
                    ]
                }, 
                "creator_id": 3, 
                "extra": {
                    "owner": true
                }, 
                "id": 4, 
                "modified_at": "2013-11-24T06:50:54.000Z", 
                "name": "test proj by a@example.com", 
                "owner": true, 
                "priority": 1, 
                "tags": [
                    {
                        "id": 3, 
                        "tag": "system:role:guest"
                    }, 
                    {
                        "id": 5, 
                        "tag": "system:job:acceptable"
                    }
                ], 
                "users": [
                    {
                        "created_at": "2013-11-24T06:50:07.000Z", 
                        "email": "a@example.com", 
                        "extra": {
                            "owner": true
                        }, 
                        "id": 3, 
                        "modified_at": "2013-11-24T06:50:54.000Z", 
                        "name": "", 
                        "owner": true, 
                        "priority": 1, 
                        "tags": [
                            "system:role:guest"
                        ]
                    }
                ]
            }
        ]

- Get one project

        GET /api/projects/:project?access_token=:access_token

    Examples:

        $ http http://localhost:9000/api/projects/4 access_token==b0c86590-54d4-11e3-b654-b932b6c09042 
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 944
        Content-Type: application/json; charset=utf-8
        Date: Sun, 24 Nov 2013 06:55:53 GMT
        X-Powered-By: Express

        {
            "created_at": "2013-11-24T06:50:54.000Z", 
            "creator": {
                "created_at": "2013-11-24T06:50:07.000Z", 
                "email": "a@example.com", 
                "id": 3, 
                "modified_at": "2013-11-24T06:50:54.000Z", 
                "name": "", 
                "priority": 1, 
                "tags": [
                    "system:role:guest"
                ]
            }, 
            "creator_id": 3, 
            "extra": {
                "owner": true
            }, 
            "id": 4, 
            "modified_at": "2013-11-24T06:50:54.000Z", 
            "name": "test proj by a@example.com", 
            "owner": true, 
            "priority": 1, 
            "tags": [
                {
                    "id": 3, 
                    "tag": "system:role:guest"
                }, 
                {
                    "id": 5, 
                    "tag": "system:job:acceptable"
                }
            ], 
            "users": [
                {
                    "created_at": "2013-11-24T06:50:07.000Z", 
                    "email": "a@example.com", 
                    "extra": {
                        "owner": true
                    }, 
                    "id": 3, 
                    "modified_at": "2013-11-24T06:50:54.000Z", 
                    "name": "", 
                    "owner": true, 
                    "priority": 1, 
                    "tags": [
                        "system:role:guest"
                    ]
                }
            ]
        }

- Add user to project (only creator has the permission)

        POST /api/projects/:project/add_user?access_token=:access_token

        {"email": "xxxx@test.com"}

    Examples:

        $ http POST http://localhost:9000/api/projects/1/add_user access_token==f4c06700-533c-11e3-8508-a36192feacb2 email=a@test.com
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 2
        Content-Type: text/plain
        Date: Fri, 22 Nov 2013 09:53:55 GMT
        X-Powered-By: Express

        OK

- Remove user from project (only creator has the permission)

        POST /api/projects/:project/remove_user?access_token=:access_token

        {"email": "xxxx@test.com"}

    Examples:

        $ http POST http://localhost:9000/api/projects/1/remove_user access_token==f4c06700-533c-11e3-8508-a36192feacb2 email=a@test.com
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 2
        Content-Type: text/plain
        Date: Sat, 23 Nov 2013 06:08:56 GMT
        X-Powered-By: Express

        OK

- List devices the project has access permission

        GET /api/projects/:project/devices?access_token=:access_token

    Examples:

        $ http http://localhost:9000/api/projects/4/devices access_token==03227250-54c0-11e3-ba49-7903e87f27a9
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 921
        Content-Type: application/json; charset=utf-8
        Date: Sun, 24 Nov 2013 13:07:36 GMT
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
                "id": "84:4b:f5:8a:a8:8f-014E05DE0F02000E", 
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
                    "system:role:admin", 
                    "system:role:guest", 
                    "system:job:acceptable"
                ], 
                "workstation": {
                    "ip": "192.168.0.66", 
                    "mac": "84:4b:f5:8a:a8:8f", 
                    "port": 8000
                }
            }
        ]

## Repos

- Get available repositories list

        GET /api/repos

    Examples:

        $ http http://localhost:9000/api/repos
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 17314
        Content-Type: application/json; charset=utf-8
        Date: Tue, 18 Mar 2014 09:10:27 GMT
        ETag: "-1370966815"
        Set-Cookie: connect.sess=s%3Aj%3A%7B%22passport%22%3A%7B%7D%7D.uDnQVi2orSN6V9TG3bFicsfJ7L2cyqxNxsiAqplvrrQ; Path=/; HttpOnly
        X-Powered-By: Express

        [
            {
                "archive_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/{archive_format}{/ref}",
                "assignees_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/assignees{/user}",
                "blobs_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/git/blobs{/sha}",
                "branches_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/branches{/branch}",
                "clone_url": "https://github.com/xiaocong/opentest.task-demo-test.git",
                "collaborators_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/collaborators{/collaborator}",
                "comments_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/comments{/number}",
                "commits_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/commits{/sha}",
                "compare_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/compare/{base}...{head}",
                "contents_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/contents/{+path}",
                "contributors_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/contributors",
                "created_at": "2013-10-22T04:08:59Z",
                "default_branch": "master",
                "description": "",
                "downloads_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/downloads",
                "events_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/events",
                "fork": false,
                "forks": 0,
                "forks_count": 0,
                "forks_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/forks",
                "full_name": "xiaocong/opentest.task-demo-test",
                "git_commits_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/git/commits{/sha}",
                "git_refs_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/git/refs{/sha}",
                "git_tags_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/git/tags{/sha}",
                "git_url": "git://github.com/xiaocong/opentest.task-demo-test.git",
                "has_downloads": true,
                "has_issues": true,
                "has_wiki": true,
                "homepage": null,
                "hooks_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/hooks",
                "html_url": "https://github.com/xiaocong/opentest.task-demo-test",
                "id": 13762768,
                "issue_comment_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/issues/comments/{number}",
                "issue_events_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/issues/events{/number}",
                "issues_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/issues{/number}",
                "keys_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/keys{/key_id}",
                "labels_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/labels{/name}",
                "language": "Python",
                "languages_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/languages",
                "master_branch": "master",
                "merges_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/merges",
                "milestones_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/milestones{/number}",
                "mirror_url": null,
                "name": "opentest.task-demo-test",
                "notifications_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/notifications{?since,all,participating}",
                "open_issues": 0,
                "open_issues_count": 0,
                "owner":
                    "avatar_url": "https://avatars.githubusercontent.com/u/1559756",
                    "events_url": "https://api.github.com/users/xiaocong/events{/privacy}",
                    "followers_url": "https://api.github.com/users/xiaocong/followers",
                    "following_url": "https://api.github.com/users/xiaocong/following{/other_user}",
                    "gists_url": "https://api.github.com/users/xiaocong/gists{/gist_id}",
                    "gravatar_id": "5c95e08c562a7162e678ef88fbcb9201",
                    "html_url": "https://github.com/xiaocong",
                    "id": 1559756,
                    "login": "xiaocong",
                    "organizations_url": "https://api.github.com/users/xiaocong/orgs",
                    "received_events_url": "https://api.github.com/users/xiaocong/received_events",
                    "repos_url": "https://api.github.com/users/xiaocong/repos",
                    "site_admin": false,
                    "starred_url": "https://api.github.com/users/xiaocong/starred{/owner}{/repo}",
                    "subscriptions_url": "https://api.github.com/users/xiaocong/subscriptions",
                    "type": "User",
                    "url": "https://api.github.com/users/xiaocong
                },
                "private": false,
                "pulls_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/pulls{/number}",
                "pushed_at": "2014-02-20T03:06:21Z",
                "releases_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/releases{/id}",
                "score": 12.465622,
                "size": 216,
                "ssh_url": "git@github.com:xiaocong/opentest.task-demo-test.git",
                "stargazers_count": 0,
                "stargazers_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/stargazers",
                "statuses_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/statuses/{sha}",
                "subscribers_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/subscribers",
                "subscription_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/subscription",
                "svn_url": "https://github.com/xiaocong/opentest.task-demo-test",
                "tags_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/tags",
                "teams_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/teams",
                "trees_url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test/git/trees{/sha}",
                "updated_at": "2014-03-03T13:15:07Z",
                "url": "https://api.github.com/repos/xiaocong/opentest.task-demo-test",
                "watchers": 0,
                "watchers_count": 0
            },
            ...
        ]

- Get task repository's evnironment variables, which is required during task creation.

        GET /api/repos/:user/:repo/env

    Examples:

        $ http localhost:9000/api/repos/xiaocong/opentest.task-demo-test/env
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 333
        Content-Type: application/json; charset=utf-8
        Date: Tue, 18 Mar 2014 09:16:15 GMT
        ETag: "-1205959222"
        Set-Cookie: connect.sess=s%3Aj%3A%7B%22passport%22%3A%7B%7D%7D.uDnQVi2orSN6V9TG3bFicsfJ7L2cyqxNxsiAqplvrrQ; Path=/; HttpOnly
        X-Powered-By: Express

        {
            "exclusive": {
                "exclusive": true,
                "fix": false,
                "options": []
            },
            "fix-field": {
                "exclusive": false,
                "fix": true,
                "options": [
                    "a",
                    "b",
                    "c"
                ]
            },
            "list-field": {
                "exclusive": false,
                "fix": false,
                "options": [
                    1,
                    2,
                    3,
                    4,
                    5
                ]
            }
        }

## Tasks

- Add task

        POST /api/tasks?access_token=:access_token&project=:project

        {
            "name": "task name", 
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
    - `jobs[].repo_url` are mandatory.
    - `name` is a human readable string for the task.
    - 'jobs' is a job array of the task. One job will be created in case the parameter is not set.
    - `jobs[].no` is internal job identifier in the task, it should be bwtween 0 and `jobs.length-1`, used in `r_job_nos`. If not assigned, it will be set as the index in the jobs array.
    - `jobs[].r_type` can be one of `none`, `exclusive` and `dependency`.
        - `none`, default value, means all jobs in the task are independent.
        - `exclusive`, means the job should not be run when any one in `r_job_nos` is running.
        - `dependency`, means the job should not be run if any one in `r_job_nos` is not finished.
    - `jobs[].r_job_nos` is an array of `jobs[].no`.
    - `jobs[].repo_url` is the repo url of the job. It's mandatory.
    - `jobs[].device_filter` is the filter condition for the job. When its all fields have the same value as a device, it means the device can run the job.
    - `jobs[].device_filter.tags` contains all required tags. Matched device must has all tags in it.
    - `jobs[].environ` contains all variables that will be passed to job shell environment.
    - `environ`, `device_filter`, `repo_url`, `repo_branch` can be set once at the same level of `jobs`, if you want not to set it at every job.

    Examples:

        $ http POST http://localhost:9000/api/tasks project=1 access_token=f4c06700-533c-11e3-8508-a36192feacb2 repo_url=https://github.com/xiaocong/demo_test.git jobs:='[{},{},{}]'
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 2115
        Content-Type: application/json; charset=utf-8
        Date: Sat, 23 Nov 2013 07:04:23 GMT
        X-Powered-By: Express

        {
            "created_at": "2013-11-23T07:04:23.569Z", 
            "creator_id": 2, 
            "description": "Task created by test@example.com at Sat Nov 23 2013 15:04:23 GMT+0800 (CST) with 3 job(s).", 
            "id": 1, 
            "jobs": [
                {
                    "created_at": "2013-11-23T07:04:23.690Z", 
                    "device_filter": {
                        "tags": [
                            "system:role:guest", 
                            "system:job:acceptable"
                        ]
                    }, 
                    "device_id": null, 
                    "environ": {}, 
                    "exit_code": null, 
                    "id": 1, 
                    "modified_at": "2013-11-23T07:04:23.690Z", 
                    "no": 0, 
                    "priority": 1, 
                    "r_job_nos": [], 
                    "r_type": "none", 
                    "repo_branch": null, 
                    "repo_passowrd": null, 
                    "repo_url": "https://github.com/xiaocong/demo_test.git", 
                    "repo_username": null, 
                    "status": "new", 
                    "task_id": 1
                }, 
                {
                    "created_at": "2013-11-23T07:04:23.754Z", 
                    "device_filter": {
                        "tags": [
                            "system:role:guest", 
                            "system:job:acceptable"
                        ]
                    }, 
                    "device_id": null, 
                    "environ": {}, 
                    "exit_code": null, 
                    "id": 2, 
                    "modified_at": "2013-11-23T07:04:23.754Z", 
                    "no": 1, 
                    "priority": 1, 
                    "r_job_nos": [], 
                    "r_type": "none", 
                    "repo_branch": null, 
                    "repo_passowrd": null, 
                    "repo_url": "https://github.com/xiaocong/demo_test.git", 
                    "repo_username": null, 
                    "status": "new", 
                    "task_id": 1
                }, 
                {
                    "created_at": "2013-11-23T07:04:23.830Z", 
                    "device_filter": {
                        "tags": [
                            "system:role:guest", 
                            "system:job:acceptable"
                        ]
                    }, 
                    "device_id": null, 
                    "environ": {}, 
                    "exit_code": null, 
                    "id": 3, 
                    "modified_at": "2013-11-23T07:04:23.830Z", 
                    "no": 2, 
                    "priority": 1, 
                    "r_job_nos": [], 
                    "r_type": "none", 
                    "repo_branch": null, 
                    "repo_passowrd": null, 
                    "repo_url": "https://github.com/xiaocong/demo_test.git", 
                    "repo_username": null, 
                    "status": "new", 
                    "task_id": 1
                }
            ], 
            "modified_at": "2013-11-23T07:04:23.569Z", 
            "name": "Task - Sat Nov 23 2013 15:04:23 GMT+0800 (CST)", 
            "project_id": 1
        }

- Get a list of tasks

        GET /api/tasks?access_token=:access_token[&project=:project][&status=:status][&page=:page][&page_count=:page_count]

    Note:

    - Returns tasks in projects that the user has permission to access.
    - If project is specified, only tasks in the project will return.
    - `status` parameter can be `all`, `finished` or `living`, default is `all`

    Examples:

        $ http http://localhost:9000/api/tasks access_token==f4c06700-533c-11e3-8508-a36192feacb2 project==1
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 4461
        Content-Type: application/json; charset=utf-8
        Date: Sat, 23 Nov 2013 07:26:14 GMT
        ETag: "240551036"
        X-Powered-By: Express

        {
            "page": 0, 
            "page_count": 16, 
            "pages": 1, 
            "status": "all", 
            "tasks": [
                {
                    "created_at": "2013-11-23T07:05:53.000Z", 
                    "creator": {
                        "created_at": "2013-11-22T06:07:42.000Z", 
                        "email": "test@example.com", 
                        "id": 2, 
                        "modified_at": "2013-11-23T06:11:29.000Z", 
                        "name": ""
                    }, 
                    "creator_id": 2, 
                    "description": "Task created by test@example.com at Sat Nov 23 2013 15:05:53 GMT+0800 (CST) with 1 job(s).", 
                    "id": 2, 
                    "jobs": [
                        {
                            "created_at": "2013-11-23T07:05:53.000Z", 
                            "device_filter": {
                                "tags": [
                                    "system:role:guest", 
                                    "system:job:acceptable"
                                ]
                            }, 
                            "device_id": 2, 
                            "environ": {}, 
                            "exit_code": 0, 
                            "id": 4, 
                            "modified_at": "2013-11-23T07:21:35.000Z", 
                            "no": 0, 
                            "priority": 1, 
                            "r_job_nos": [], 
                            "r_type": "none", 
                            "repo_branch": null, 
                            "repo_passowrd": null, 
                            "repo_url": "https://github.com/xiaocong/demo_test.git", 
                            "repo_username": null, 
                            "status": "finished", 
                            "task_id": 2
                        }
                    ], 
                    "modified_at": "2013-11-23T07:21:35.000Z", 
                    "name": "Task - Sat Nov 23 2013 15:05:53 GMT+0800 (CST)", 
                    "project": {
                        "created_at": "2013-11-22T06:12:26.000Z", 
                        "creator_id": 2, 
                        "id": 1, 
                        "modified_at": "2013-11-22T06:12:26.000Z", 
                        "name": "my demo project", 
                        "priority": 1
                    }, 
                    "project_id": 1
                }, 
                {
                    "created_at": "2013-11-23T07:04:23.000Z", 
                    "creator": {
                        "created_at": "2013-11-22T06:07:42.000Z", 
                        "email": "test@example.com", 
                        "id": 2, 
                        "modified_at": "2013-11-23T06:11:29.000Z", 
                        "name": ""
                    }, 
                    "creator_id": 2, 
                    "description": "Task created by test@example.com at Sat Nov 23 2013 15:04:23 GMT+0800 (CST) with 3 job(s).", 
                    "id": 1, 
                    "jobs": [
                        {
                            "created_at": "2013-11-23T07:04:23.000Z", 
                            "device_filter": {
                                "tags": [
                                    "system:role:guest", 
                                    "system:job:acceptable"
                                ]
                            }, 
                            "device_id": 2, 
                            "environ": {}, 
                            "exit_code": 0, 
                            "id": 1, 
                            "modified_at": "2013-11-23T07:15:30.000Z", 
                            "no": 0, 
                            "priority": 1, 
                            "r_job_nos": [], 
                            "r_type": "none", 
                            "repo_branch": null, 
                            "repo_passowrd": null, 
                            "repo_url": "https://github.com/xiaocong/demo_test.git", 
                            "repo_username": null, 
                            "status": "finished", 
                            "task_id": 1
                        }, 
                        {
                            "created_at": "2013-11-23T07:04:23.000Z", 
                            "device_filter": {
                                "tags": [
                                    "system:role:guest", 
                                    "system:job:acceptable"
                                ]
                            }, 
                            "device_id": 2, 
                            "environ": {}, 
                            "exit_code": 0, 
                            "id": 2, 
                            "modified_at": "2013-11-23T07:18:02.000Z", 
                            "no": 1, 
                            "priority": 1, 
                            "r_job_nos": [], 
                            "r_type": "none", 
                            "repo_branch": null, 
                            "repo_passowrd": null, 
                            "repo_url": "https://github.com/xiaocong/demo_test.git", 
                            "repo_username": null, 
                            "status": "finished", 
                            "task_id": 1
                        }, 
                        {
                            "created_at": "2013-11-23T07:04:23.000Z", 
                            "device_filter": {
                                "tags": [
                                    "system:role:guest", 
                                    "system:job:acceptable"
                                ]
                            }, 
                            "device_id": 2, 
                            "environ": {}, 
                            "exit_code": 0, 
                            "id": 3, 
                            "modified_at": "2013-11-23T07:20:04.000Z", 
                            "no": 2, 
                            "priority": 1, 
                            "r_job_nos": [], 
                            "r_type": "none", 
                            "repo_branch": null, 
                            "repo_passowrd": null, 
                            "repo_url": "https://github.com/xiaocong/demo_test.git", 
                            "repo_username": null, 
                            "status": "finished", 
                            "task_id": 1
                        }
                    ], 
                    "modified_at": "2013-11-23T07:20:04.000Z", 
                    "name": "Task - Sat Nov 23 2013 15:04:23 GMT+0800 (CST)", 
                    "project": {
                        "created_at": "2013-11-22T06:12:26.000Z", 
                        "creator_id": 2, 
                        "id": 1, 
                        "modified_at": "2013-11-22T06:12:26.000Z", 
                        "name": "my demo project", 
                        "priority": 1
                    }, 
                    "project_id": 1
                }
            ]
        }

- Get a task

        GET /api/tasks/:task?access_token=:access_token

    Examples:

        $ http http://localhost:9000/api/tasks/1 access_token==f4c06700-533c-11e3-8508-a36192feacb2
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 2482
        Content-Type: application/json; charset=utf-8
        Date: Sat, 23 Nov 2013 07:28:15 GMT
        ETag: "-27096222"
        X-Powered-By: Express

        {
            "created_at": "2013-11-23T07:04:23.000Z", 
            "creator": {
                "created_at": "2013-11-22T06:07:42.000Z", 
                "email": "test@example.com", 
                "id": 2, 
                "modified_at": "2013-11-23T06:11:29.000Z", 
                "name": ""
            }, 
            "creator_id": 2, 
            "description": "Task created by test@example.com at Sat Nov 23 2013 15:04:23 GMT+0800 (CST) with 3 job(s).", 
            "id": 1, 
            "jobs": [
                {
                    "created_at": "2013-11-23T07:04:23.000Z", 
                    "device_filter": {
                        "tags": [
                            "system:role:guest", 
                            "system:job:acceptable"
                        ]
                    }, 
                    "device_id": 2, 
                    "environ": {}, 
                    "exit_code": 0, 
                    "id": 1, 
                    "modified_at": "2013-11-23T07:15:30.000Z", 
                    "no": 0, 
                    "priority": 1, 
                    "r_job_nos": [], 
                    "r_type": "none", 
                    "repo_branch": null, 
                    "repo_passowrd": null, 
                    "repo_url": "https://github.com/xiaocong/demo_test.git", 
                    "repo_username": null, 
                    "status": "finished", 
                    "task_id": 1
                }, 
                {
                    "created_at": "2013-11-23T07:04:23.000Z", 
                    "device_filter": {
                        "tags": [
                            "system:role:guest", 
                            "system:job:acceptable"
                        ]
                    }, 
                    "device_id": 2, 
                    "environ": {}, 
                    "exit_code": 0, 
                    "id": 2, 
                    "modified_at": "2013-11-23T07:18:02.000Z", 
                    "no": 1, 
                    "priority": 1, 
                    "r_job_nos": [], 
                    "r_type": "none", 
                    "repo_branch": null, 
                    "repo_passowrd": null, 
                    "repo_url": "https://github.com/xiaocong/demo_test.git", 
                    "repo_username": null, 
                    "status": "finished", 
                    "task_id": 1
                }, 
                {
                    "created_at": "2013-11-23T07:04:23.000Z", 
                    "device_filter": {
                        "tags": [
                            "system:role:guest", 
                            "system:job:acceptable"
                        ]
                    }, 
                    "device_id": 2, 
                    "environ": {}, 
                    "exit_code": 0, 
                    "id": 3, 
                    "modified_at": "2013-11-23T07:20:04.000Z", 
                    "no": 2, 
                    "priority": 1, 
                    "r_job_nos": [], 
                    "r_type": "none", 
                    "repo_branch": null, 
                    "repo_passowrd": null, 
                    "repo_url": "https://github.com/xiaocong/demo_test.git", 
                    "repo_username": null, 
                    "status": "finished", 
                    "task_id": 1
                }
            ], 
            "modified_at": "2013-11-23T07:20:04.000Z", 
            "name": "Task - Sat Nov 23 2013 15:04:23 GMT+0800 (CST)", 
            "project": {
                "created_at": "2013-11-22T06:12:26.000Z", 
                "creator_id": 2, 
                "id": 1, 
                "modified_at": "2013-11-22T06:12:26.000Z", 
                "name": "my demo project", 
                "priority": 1
            }, 
            "project_id": 1
        }

- Cancel task

        POST /api/tasks/:task/cancel?access_token=:access_token

    Examples:

        $ http POST http://localhost:9000/api/tasks/1/cancel access_token==f4c06700-533c-11e3-8508-a36192feacb2
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 2
        Content-Type: text/plain
        Date: Sat, 23 Nov 2013 07:33:47 GMT
        X-Powered-By: Express

        OK

- Restart task

        POST /api/tasks/:task/restart?access_token=:access_token

    Examples:

        $ http POST http://localhost:9000/api/tasks/1/restart access_token==f4c06700-533c-11e3-8508-a36192feacb2
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 2
        Content-Type: text/plain
        Date: Sat, 23 Nov 2013 07:34:31 GMT
        X-Powered-By: Express

        OK

- Add a job to task

        POST /api/tasks/:task/jobs?access_token=:access_token

        {...}

    Note: See add task API for detailed parameters.

    Examples:

        $ POST http://localhost:9000/api/tasks/1/jobs access_token==f4c06700-533c-11e3-8508-a36192feacb2 repo_url=https://github.com/xiaocong/demo_test.git
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 498
        Content-Type: application/json; charset=utf-8
        Date: Sat, 23 Nov 2013 07:41:07 GMT
        X-Powered-By: Express

        {
            "created_at": "2013-11-23T07:41:07.224Z", 
            "device_filter": {
                "tags": [
                    "system:role:guest", 
                    "system:job:acceptable"
                ]
            }, 
            "device_id": null, 
            "environ": {}, 
            "exit_code": null, 
            "id": 5, 
            "modified_at": "2013-11-23T07:41:07.224Z", 
            "no": 3, 
            "priority": 1, 
            "r_job_nos": [], 
            "r_type": "none", 
            "repo_branch": null, 
            "repo_passowrd": null, 
            "repo_url": "https://github.com/xiaocong/demo_test.git", 
            "repo_username": null, 
            "status": "new", 
            "task_id": 1
        }

- Update a job

        POST /api/tasks/:task/jobs/:no?access_token=:access_token

        {...}

    Note:

    - See add task API for detailed parameters. 
    - Started job can not be updated.
    - Job status can not be changed.
    - Job No. starts from 0

    Examples:

        $ http POST http://localhost:9000/api/tasks/1/jobs/0 access_token==f4c06700-533c-11e3-8508-a36192feacb2 repo_url=https://github.com/xiaocong/demo_test.git environ:='{"ENV":"will be set to job shell environments."}'
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 552
        Content-Type: application/json; charset=utf-8
        Date: Sat, 23 Nov 2013 08:03:17 GMT
        X-Powered-By: Express

        {
            "created_at": "2013-11-23T07:04:23.000Z", 
            "device_filter": {
                "tags": [
                    "system:role:guest", 
                    "system:job:acceptable"
                ]
            }, 
            "device_id": 2, 
            "environ": {
                "ENV": "will be set to job shell environments."
            }, 
            "exit_code": 0, 
            "id": 1, 
            "modified_at": "2013-11-23T08:03:17.470Z", 
            "no": 0, 
            "priority": 1, 
            "r_job_nos": [], 
            "r_type": "none", 
            "repo_branch": null, 
            "repo_passowrd": null, 
            "repo_url": "https://github.com/xiaocong/demo_test.git", 
            "repo_username": null, 
            "status": "finished", 
            "task_id": 1
        }

- Cancel a job

        POST /api/tasks/:task/jobs/:no/cancel?access_token=:access_token

    Examples:

        $ http POST http://localhost:9000/api/tasks/1/jobs/0/cancel access_token==f4c06700-533c-11e3-8508-a36192feacb2 
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 553
        Content-Type: application/json; charset=utf-8
        Date: Sat, 23 Nov 2013 08:05:21 GMT
        X-Powered-By: Express

        {
            "created_at": "2013-11-23T07:04:23.000Z", 
            "device_filter": {
                "tags": [
                    "system:role:guest", 
                    "system:job:acceptable"
                ]
            }, 
            "device_id": 2, 
            "environ": {
                "ENV": "will be set to job shell environments."
            }, 
            "exit_code": 0, 
            "id": 1, 
            "modified_at": "2013-11-23T08:05:21.398Z", 
            "no": 0, 
            "priority": 1, 
            "r_job_nos": [], 
            "r_type": "none", 
            "repo_branch": null, 
            "repo_passowrd": null, 
            "repo_url": "https://github.com/xiaocong/demo_test.git", 
            "repo_username": null, 
            "status": "cancelled", 
            "task_id": 1
        }

- Restart a job

        POST /api/tasks/:task/jobs/:no/restart?access_token=:access_token

    Examples:

        $ http POST http://localhost:9000/api/tasks/1/jobs/0/restart access_token==f4c06700-533c-11e3-8508-a36192feacb2 
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 547
        Content-Type: application/json; charset=utf-8
        Date: Sat, 23 Nov 2013 08:05:15 GMT
        X-Powered-By: Express

        {
            "created_at": "2013-11-23T07:04:23.000Z", 
            "device_filter": {
                "tags": [
                    "system:role:guest", 
                    "system:job:acceptable"
                ]
            }, 
            "device_id": 2, 
            "environ": {
                "ENV": "will be set to job shell environments."
            }, 
            "exit_code": 0, 
            "id": 1, 
            "modified_at": "2013-11-23T08:05:15.553Z", 
            "no": 0, 
            "priority": 1, 
            "r_job_nos": [], 
            "r_type": "none", 
            "repo_branch": null, 
            "repo_passowrd": null, 
            "repo_url": "https://github.com/xiaocong/demo_test.git", 
            "repo_username": null, 
            "status": "new", 
            "task_id": 1
        }

- Get job stream output

        GET /api/tasks/:task/jobs/:no/stream?access_token=:access_token

    Note: It will return http chunked console output of the jobs.

    Examples:

        $ http http://localhost:9000/api/tasks/1/jobs/0/stream access_token==f4c06700-533c-11e3-8508-a36192feacb2 lines==1000
        HTTP/1.1 200 OK
        X-Powered-By: Express
        connection: keep-alive
        content-type: text/html; charset=UTF-8
        date: Sat, 23 Nov 2013 08:24:07 GMT
        server: gunicorn/18.0
        transfer-encoding: chunked

        Cloning into '/home/pi/jobs/1/repo'...
        Running virtualenv with interpreter /usr/bin/python2.7
        New python executable in .venv/bin/python2.7
        Also creating executable in .venv/bin/python
        Installing setuptools............done.
        Installing pip...............done.
        Downloading/unpacking uiautomator
          Downloading uiautomator-0.1.16.tar.gz
          Running setup.py egg_info for package uiautomator
            warning: no previously-included files matching '*.pyc' found anywhere in distribution

- Get job's files

        GET /api/tasks/:task/jobs/:no/files/:file_path?access_token=:access_token

    Note:

    - If the file_path is a directory, it will return an array of files under the directory.
    - If the file_path is a file, it will return the content the file.

    Examples:

        $ http http://localhost:9000/api/tasks/1/jobs/0/stream access_token==f4c06700-533c-11e3-8508-a36192feacb2 lines==1000
        HTTP/1.1 200 OK
        X-Powered-By: Express
        connection: keep-alive
        content-type: text/html; charset=UTF-8
        date: Sat, 23 Nov 2013 08:24:07 GMT
        server: gunicorn/18.0
        transfer-encoding: chunked

        Cloning into '/home/pi/jobs/1/repo'...
        Running virtualenv with interpreter /usr/bin/python2.7
        New python executable in .venv/bin/python2.7
        Also creating executable in .venv/bin/python
        Installing setuptools............done.
        Installing pip...............done.
        Downloading/unpacking uiautomator
          Downloading uiautomator-0.1.16.tar.gz
          Running setup.py egg_info for package uiautomator
            warning: no previously-included files matching '*.pyc' found anywhere in distribution       

- Take screenshot of a device on which the job is running

        GET /api/tasks/:task/jobs/:no/screenshot?access_token=:access_token[&width=:width&height=:height]

    Notes:

    - It's same as device screenshoot API, but this API doesn't need admin permission.
    - It can only work on running job. For not running job, it returns 403 Forbidden.

- Get test results of a job in case it has.

        GET /api/tasks/:task/jobs/:no/result?access_token=:access_token

    Notes

    - It parses the content in file `$JOB_ID/$WORKSPACE/result.txt`. If the file doesn't exist, it returns an error.
    - You can pass query parameter `r` e.g. `r=fail,error` to filter the specified results.
    - You can pass query parameters `page` and `page_count` to only return the result of the specified page.

    Examples:

        $ http http://localhost:9000/api/tasks/4/jobs/0/result access_token==1177c620-694c-11e3-877d-013bcec48b5e
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 1260
        Content-Type: application/json; charset=utf-8
        Date: Mon, 06 Jan 2014 05:33:30 GMT
        ETag: "-1664147239"
        Set-Cookie: connect.sess=s%3Aj%3A%7B%22passport%22%3A%7B%7D%7D.uDnQVi2orSN6V9TG3bFicsfJ7L2cyqxNxsiAqplvrrQ; Path=/; HttpOnly
        X-Powered-By: Express

        {
            "end_at": "2013-01-08T07:06:37.000Z", 
            "error": 1, 
            "fail": 1, 
            "pass": 1, 
            "results": [
                {
                    "end_at": "2013-01-08T06:05:36.000Z", 
                    "name": "class.method", 
                    "result": "pass", 
                    "start_at": "2013-01-08T06:05:36.000Z"
                }, 
                {
                    "end_at": "2013-01-08T07:06:37.000Z", 
                    "expect": "/api/tasks/4/jobs/0/files/workspace/path_to_expect/expect.png", 
                    "log": "/api/tasks/4/jobs/0/files/workspace/path_to_whenfailure/log.zip", 
                    "name": "class.method", 
                    "result": "fail", 
                    "screenshot_at_failure": "/api/tasks/4/jobs/0/files/workspace/path_to_whenfailure/failure.png", 
                    "start_at": "2013-01-08T06:05:36.000Z", 
                    "trace": "traceinfo"
                }, 
                {
                    "end_at": "2013-01-08T07:06:37.000Z", 
                    "expect": "/api/tasks/4/jobs/0/files/workspace/path_to_expect/expect.png", 
                    "log": "/api/tasks/4/jobs/0/files/workspace/path_to_log/log.zip", 
                    "name": "class.method", 
                    "result": "error", 
                    "screenshot_at_failure": "/api/tasks/4/jobs/0/files/workspace/path_to_error/failure.png", 
                    "start_at": "2013-01-08T06:05:36.000Z", 
                    "trace": "traceinfo"
                }
            ], 
            "start_at": "2013-01-08T06:05:36.000Z", 
            "total": 3
        }

[httpie]: https://github.com/jkbr/httpie
