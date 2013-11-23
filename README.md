# Remote Task Web App

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

        GET /api/tags

    Examples:

        $ http http://localhost:9000/api/tags
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 97
        Content-Type: application/json; charset=utf-8
        Date: Fri, 22 Nov 2013 06:10:00 GMT
        X-Powered-By: Express

        [
            "system:role:admin", 
            "system:role:user", 
            "system:role:guest", 
            "system:job:acceptable"
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

## Project

- Create new project

        POST /api/projects?access_token=:access_token

        {"name": "project name"}

    Examples:

        $ http http://localhost:9000/api/projects name="my demo project" access_token==f4c06700-533c-11e3-8508-a36192feacb2
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 167
        Content-Type: application/json; charset=utf-8
        Date: Fri, 22 Nov 2013 06:12:26 GMT
        X-Powered-By: Express

        {
            "created_at": "2013-11-22T06:12:26.110Z", 
            "creator_id": 2, 
            "id": 1, 
            "modified_at": "2013-11-22T06:12:26.110Z", 
            "name": "my demo project", 
            "priority": 1
        }

- List all projects that you have permission to access

        GET /api/projects?access_token=:access_token

    Examples:

        $ http http://localhost:9000/api/projects access_token==f4c06700-533c-11e3-8508-a36192feacb2
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 887
        Content-Type: application/json; charset=utf-8
        Date: Fri, 22 Nov 2013 06:14:53 GMT
        X-Powered-By: Express

        [
            {
                "created_at": "2013-11-22T06:12:26.000Z", 
                "creator": {
                    "created_at": "2013-11-22T06:07:42.000Z", 
                    "email": "test@example.com", 
                    "id": 2, 
                    "modified_at": "2013-11-22T06:12:26.000Z", 
                    "name": ""
                }, 
                "creator_id": 2, 
                "extra": {
                    "owner": true
                }, 
                "id": 1, 
                "modified_at": "2013-11-22T06:12:26.000Z", 
                "name": "my demo project", 
                "owner": true, 
                "priority": 1, 
                "tags": [
                    {
                        "id": 3, 
                        "tag": "system:role:guest"
                    }, 
                    {
                        "id": 4, 
                        "tag": "system:job:acceptable"
                    }
                ], 
                "users": [
                    {
                        "created_at": "2013-11-22T06:07:42.000Z", 
                        "email": "test@example.com", 
                        "extra": {
                            "owner": true
                        }, 
                        "id": 2, 
                        "modified_at": "2013-11-22T06:12:26.000Z", 
                        "name": "", 
                        "owner": true
                    }
                ]
            }
        ]

- Get one project

        GET /api/projects/:project?access_token=:access_token

    Examples:

        $ http http://localhost:9000/api/projects/1 access_token==f4c06700-533c-11e3-8508-a36192feacb2
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 799
        Content-Type: application/json; charset=utf-8
        Date: Fri, 22 Nov 2013 06:34:07 GMT
        X-Powered-By: Express

        {
            "created_at": "2013-11-22T06:12:26.000Z", 
            "creator": {
                "created_at": "2013-11-22T06:07:42.000Z", 
                "email": "test@example.com", 
                "id": 2, 
                "modified_at": "2013-11-22T06:12:26.000Z", 
                "name": ""
            }, 
            "creator_id": 2, 
            "extra": {
                "owner": true
            }, 
            "id": 1, 
            "modified_at": "2013-11-22T06:12:26.000Z", 
            "name": "my demo project", 
            "owner": true, 
            "priority": 1, 
            "tags": [
                {
                    "id": 3, 
                    "tag": "system:role:guest"
                }, 
                {
                    "id": 4, 
                    "tag": "system:job:acceptable"
                }
            ], 
            "users": [
                {
                    "created_at": "2013-11-22T06:07:42.000Z", 
                    "email": "test@example.com", 
                    "extra": {
                        "owner": true
                    }, 
                    "id": 2, 
                    "modified_at": "2013-11-22T06:12:26.000Z", 
                    "name": "", 
                    "owner": true
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

## Devices

- Get attached devices that the specified project has permission to access.

        GET /api/devices?access_token=:access_token&project=:project

    Examples:

        $ http http://localhost:9000/api/devices access_token==f4c06700-533c-11e3-8508-a36192feacb2 project==1
        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 922
        Content-Type: application/json; charset=utf-8
        Date: Sat, 23 Nov 2013 06:21:12 GMT
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
                    "system:role:admin", 
                    "system:role:guest", 
                    "system:job:acceptable"
                ], 
                "workstation": {
                    "ip": "192.168.4.232", 
                    "mac": "00:26:b9:e7:a2:3b", 
                    "port": 8000
                }
            }
        ]

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

        GET /api/tasks?access_token=:access_token[&project=:project]

    Note:

    - Only tasks in projects that the user has permission to access will return.
    - If project is specified, only tasks in the project will return.

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
            "running_only": false, 
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

[httpie]: https://github.com/jkbr/httpie
