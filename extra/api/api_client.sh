#!/bin/bash
#
# Redmine plugin for Document Management System "Features"
#
# Karel Pičman <karel.picman@kontron.com>
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

# Authentication as input parameters either as login + password or the API key
#USER_LOGIN="${1}"
#USER_PASSWORD="${2}"
USER_API_KEY="${1}"

# BOTH XML and JSON formats are supported.
# Just replace .xml with .json
#
# Uncomment a corresponding line to the case you would like to test

# 1. List of documents in a given folder or the root folder
#curl -v -H "Content-Type: application/xml" -X GET -u ${USER_LOGIN}:${USER_PASSWORD} http://localhost:3000/projects/12/dmsf.xml
#curl -v -H "Content-Type: application/xml" -X GET -u ${USER_LOGIN}:${USER_PASSWORD} http://localhost:3000/projects/12/dmsf.xml?folder_id=5155
#curl -v -H "Content-Type: application/xml" -X GET -u ${USER_LOGIN}:${USER_PASSWORD} "http://localhost:3000/projects/12/dmsf.xml?limit=2&offset=1"

# 2. Get a document
#curl -v -H "Content-Type: application/xml" -X GET -u ${USER_LOGIN}:${USER_PASSWORD} http://localhost:3000/dmsf/files/17216.xml
#curl -v -H "Content-Type: application/octet-stream" -X GET -u ${USER_LOGIN}:${USER_PASSWORD} http://localhost:3000/dmsf/files/41532/download > file.txt

# 3. Upload a document into a given folder or the root folder
#curl --data-binary "@cat.gif" -H "Content-Type: application/octet-stream" -X POST -u ${USER_LOGIN}:${USER_PASSWORD} http://localhost:3000/projects/12/dmsf/upload.xml?filename=cat.gif
#curl -v -H "Content-Type: application/xml" -X POST --data "@file.xml" -u ${USER_LOGIN}:${USER_PASSWORD} http://localhost:3000/projects/12/dmsf/commit.xml

# 4. Create a new revision
#curl -v -H "Content-Type: application/xml" -X POST --data "@revision.xml" -u ${USER_LOGIN}:${USER_PASSWORD} http://localhost:3000/dmsf/files/232565/revision/create.xml

# 5. Entries operation
# 5.1 Copy document(s)/folder(s)
#curl -v -H "Content-Type: application/xml" -X POST --data "@entries.xml" -H "X-Redmine-API-Key: ${USER_API_KEY}" "http://localhost:3000/projects/3342/dmsf/entries.xml?ids[]=file-254566&copy_entries=true"
# 5.2 Move document(s)/folder(s)
#curl -v -H "Content-Type: application/xml" -X POST --data "@entries.xml" -H "X-Redmine-API-Key: ${USER_API_KEY}" "http://localhost:3000/projects/3342/dmsf/entries.xml?ids[]=file-254566&move_entries=true"
# 5.3 Download document(x)/folders(s)
#curl -v -H "Content-Type: application/octet-stream" -X POST --data "" -H "X-Redmine-API-Key: ${USER_API_KEY}" http://localhost:3000/projects/3342/dmsf/entries.xml?ids[]=file-254566
# 5.4 Delete document(x)/folder(s)
#curl -v -H "Content-Type: application/xml" -X POST --data "" -H "X-Redmine-API-Key: ${USER_API_KEY}" "http://localhost:3000/projects/3342/dmsf/entries.xml?ids[]=file-254566&delete_entries=true"

# 6. Delete a document
# a) Move to trash only
#  curl -v -H "Content-Type: application/xml" -X DELETE -u ${USER_LOGIN}:${USER_PASSWORD} http://localhost:3000/dmsf/files/196118.xml
# b) Delete permanently
#  curl -v -H "Content-Type: application/xml" -X DELETE -u ${USER_LOGIN}:${USER_PASSWORD} http://localhost:3000/dmsf/files/196118.xml?commit=yes"

# 7. Create a folder
#curl -v -H "Content-Type: application/xml" -X POST --data "@folder.xml" -u ${USER_LOGIN}:${USER_PASSWORD} http://localhost:3000/projects/12/dmsf/create.xml

# 8. List folder content & check folder existence (by folder title)
# curl -v -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: ${USERS_API_KEY}" http://localhost:3000/projects/1/dmsf.json?folder_title=Updated%20title

# 9. List folder content & check folder existence (by folder id)
# curl -v -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: ${USERS_API_KEY}" http://localhost:3000/projects/1/dmsf.json?folder_id=3
# both returns 404 not found, or json with following structure:
# {  
#   "dmsf":{
#      "found_folder":{  
#         "id":3,
#         "title":"Updated title"
#      }
#   }
#}

# 10. Update a folder
# curl -v -H "Content-Type: application/json" -X POST --data "@update-folder-payload.json" -H "X-Redmine-API-Key: ${USERS_API_KEY}" http://localhost:3000//projects/#{project_id}/dmsf/save.json?folder_id=#{folder_id}

# update-folder-payload.json 
#  {
#     "dmsf_folder": {
#       "title": title,
#       "description": description
#      },
#    }

# 11. Copy a folder
#curl -v -H "Content-Type: application/xml" -X POST --data "@file_or_folder_copy_move.xml" -H "X-Redmine-API-Key: ${USERS_API_KEY}" http://localhost:3000/dmsf/folders/53075/copy/copy.xml

# 12. Move a folder
#curl -v -H "Content-Type: application/xml" -X POST --data "@file_or_folder_copy_move.xml" -H "X-Redmine-API-Key: ${USERS_API_KEY}" http://localhost:3000/dmsf/folders/53075/copy/move.xml

# 13. Delete a folder
# a) Move to trash only
#  curl -v -H "Content-Type: application/xml" -X DELETE -u ${USER_LOGIN}:${USER_PASSWORD} http://localhost:3000/projects/2387/dmsf/delete.xml?folder_id=#{folder_id}
# b) Delete permanently
#  curl -v -H "Content-Type: application/xml" -X DELETE -u ${USER_LOGIN}:${USER_PASSWORD} "http://localhost:3000/projects/2387/dmsf/delete.xml?folder_id=#{folder_id}&commit=yes"

# 14. Create a symbolic link
# curl -v -H "Content-Type: application/xml" -X POST --data "@link.xml" -H "X-Redmine-API-Key: ${USERS_API_KEY}" http://localhost:3000/dmsf_links.xml