#!/usr/bin/env python3
import os
import json
import requests
import argparse

def download_file(url, path, headers=None):
    """下载文件并保存到 path"""
    with requests.get(url, stream=True, headers=headers) as r:
        r.raise_for_status()
        with open(path, 'wb') as f:
            for chunk in r.iter_content(chunk_size=8192):
                f.write(chunk)

def backup_releases(owner, repo, backup_dir, token=None):
    """备份 GitHub Releases"""
    os.makedirs(backup_dir, exist_ok=True)
    api_url = f"https://api.github.com/repos/{owner}/{repo}/releases"
    
    headers = {}
    if token:
        headers['Authorization'] = f'token {token}'

    print(f"[INFO] 获取 releases: {owner}/{repo}")
    response = requests.get(api_url, headers=headers)
    releases = response.json()

    if isinstance(releases, dict) and releases.get('message'):
        print(f"[ERROR] {releases['message']}")
        return

    for r in releases:
        release_id = r['id']
        release_name = r['name'].replace(" ", "_") or r['tag_name']
        release_dir = os.path.join(backup_dir, f"release-{release_id}-{release_name}")
        assets_dir = os.path.join(release_dir, 'assets')
        os.makedirs(assets_dir, exist_ok=True)

        # 保存 JSON
        json_path = os.path.join(release_dir, 'release.json')
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(r, f, indent=2, ensure_ascii=False)

        # 保存描述
        body_path = os.path.join(release_dir, 'body.md')
        with open(body_path, 'w', encoding='utf-8') as f:
            f.write(r.get('body', ''))

        # 下载 assets
        assets = r.get('assets', [])
        for a in assets:
            asset_url = a['browser_download_url']
            asset_name = a['name']
            asset_path = os.path.join(assets_dir, asset_name)
            if os.path.exists(asset_path):
                print(f"[SKIP] {asset_name} 已存在")
                continue
            print(f"[DOWNLOAD] {asset_name}")
            download_file(asset_url, asset_path, headers=headers)

    print(f"[DONE] 完成备份 {len(releases)} 个 release 到 {backup_dir}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="备份 GitHub Releases，包括 release JSON、描述文件和 assets 下载。"
    )
    parser.add_argument(
        "--owner", required=True, 
        help="GitHub 仓库所有者用户名或组织名，例如 'octocat'"
    )
    parser.add_argument(
        "--repo", required=True, 
        help="GitHub 仓库名称，例如 'Hello-World'"
    )
    parser.add_argument(
        "--backup_dir", required=True, 
        help="备份文件存放目录，程序会在此目录下创建 release 子目录"
    )
    args = parser.parse_args()

    token = input("enter token here: ").trim()
    backup_releases(args.owner, args.repo, args.backup_dir, token=args.token)
