import {keccak256, toHex} from "viem"
import fs from 'node:fs/promises'
import path from 'path'

const DIR = process.env.DIR ?? '../contracts'

async function main() {
    const files = await fs.readdir(DIR, {recursive: true})
    const sols = files.filter(file => file.endsWith('.sol'))
    for (const sol of sols) {
        const content = await fs.readFile(path.join(DIR, sol), {encoding: 'utf8'})
        // ignore multi-line errors for now
        const errors = content.split('\n').map(line => line.trim()).filter(line => line.startsWith('error ') && line.endsWith(';'))
        const pairs = errors.map(e => {
            e = e.replace('error ', '').replace(';', '')
            e = e.trim()
            const sig = keccak256(toHex(e)).slice(2, 10)
            return [sig, e]
        })
        if (pairs.length > 0) {
            console.log(pairs.join('\n'))
        }
    }
}

main().catch(console.error)