# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011-15 Karel Pičman <karel.picman@kontron.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

#!/bin/bash

# Authentication as input parameters either as login + password or the API key
# -u ${1}:${2}
# -H "X-Redmine-API-Key: ${1}"

# BOTH XML and JSON formats are supported.
# Just replace .xml with .json

# 1. List of documents in a given folder or the root folder
curl -v -H "Content-Type: application/xml" -X GET -u ${1}:${2} http://localhost:3000/projects/12/dmsf.xml
#curl -v -H "Content-Type: application/xml" -X GET -u ${1}:${2} http://localhost:3000/projects/12/dmsf.xml?folder_id=5155

# 2. Get a document
#curl -v -H "Content-Type: application/xml" -X GET -u ${1}:${2} http://localhost:3000/dmsf/files/17216.xml
#curl -v -H "Content-Type: application/octet-stream" -X GET -u ${1}:${2} http://localhost:3000/dmsf/files/41532/download > file.txt

# 3. Create a folder
#curl -v -H "Content-Type: application/xml" -X POST --data "@folder.xml" -u ${1}:${2} http://localhost:3000/projects/12/dmsf/create.xml

# 4. Upload a document into a given folder or the root folder
#curl --data-binary "@cat.gif" -H "Content-Type: application/octet-stream" -X POST -u ${1}:${2} http://localhost:3000/projects/12/dmsf/upload.xml?filename=cat.gif
#curl -v -H "Content-Type: application/xml" -X POST --data "@file.xml" -u ${1}:${2} http://localhost:3000/projects/12/dmsf/commit.xml

# 5. list folder contents & check folder existence (by folder title)
# curl -v -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: USERS_API_KEY" http://localhost:3000/projects/1/dmsf.json?folder_title=Updated%20title

# 6. list folder contents & check folder existence (by folder id)
# curl -v -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: USERS_API_KE" http://localhost:3000/projects/1/dmsf.json?folder_id=3
# both returns 404 not found, or json with following structure:
# {  
#   "dmsf":{  
#      "dmsf_folders":[  
#
#      ],
#      "total_count":0,
#      "dmsf_files":[  
#
#      ],
#      "dmsf_links":[  
#
#      ],
#      "found_folder":{  
#         "id":3,
#         "title":"Updated title"
#      }
#   }
#}

# 7. update folder
# curl -v -H "Content-Type: application/json" -X POST --data "@update-folder-payload.json" -H "X-Redmine-API-Key: USERS_API_KEY" http://localhost:3000//projects/#{project_id}/dmsf/save.json?folder_id=#{folder_id}

# update-folder-payload.json 
#  {
#     "dmsf_folder": {
#       "title": title,
#       "description": description
#      },
#    }