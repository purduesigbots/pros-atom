// The PROS build provider is a direct modification of the build-make package,
// but with awareness of the PROS_TOOLCHAIN variable

// Copyright (c) 2015 Alexander Olsson
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import fs from 'fs';
import path from 'path';
import os from 'os';
import { exec } from 'child_process';
import voucher from 'voucher';
import { EventEmitter } from 'events';


export function provideBuilder() {
  const gccErrorMatch = '(?<file>([A-Za-z]:[\\/])?[^:\\n]+):(?<line>\\d+):(?<col>\\d+):\\s*(fatal error|error):\\s*(?<message>.+)';
   const gccWarningMatch = '(?<file>([A-Za-z]:[\\/])?[^:\\n]+):(?<line>\\d+):(?<col>\\d+):\\s*(warning):\\s*(?<message>.+)';

   return class MakeBuildProvider extends EventEmitter {
   constructor(cwd) {
     super();
     this.cwd = cwd;
   }

   getNiceName() {
     return 'PROS GNU Make';
   }

   isEligible() {
     if(!atom.config.get('pros.enable'))
      return false;
     this.files = [ 'Makefile', 'GNUmakefile', 'makefile' ]
       .map(f => path.join(this.cwd, f))
       .filter(fs.existsSync);
     return this.files.length > 0;
   }

   settings() {
     const args = [ ];

     env = process.env
     if(navigator.platform == 'Win32' && !!env['PROS_TOOLCHAIN']) {
       env['PATH'] = path.join(env['PROS_TOOLCHAIN'], 'bin') + ';' + env['PATH']
     }

     const defaultTarget = {
       exec: 'make',
       name: 'PROS GNU Make: default (no target)',
       args: args,
       env: env,
       sh: false,
       errorMatch: [ gccErrorMatch ],
       warningMatch: [ gccWarningMatch ]
     };

     const promise = atom.config.get('build-make.useMake') ?
       voucher(exec, 'make -prRn', { cwd: this.cwd }) :
       voucher(fs.readFile, this.files[0]); // Only take the first file

     return promise.then(output => {
       return [ defaultTarget ].concat(output.toString('utf8')
         .split(/[\r\n]{1,2}/)
         .filter(line => /^[a-zA-Z0-9][^$#\/\t=]*:([^=]|$)/.test(line))
         .map(targetLine => targetLine.split(':').shift())
         .filter( (elem, pos, array) => (array.indexOf(elem) === pos) )
         .map(target => ({
           exec: 'make',
           args: args.concat([ target ]),
           name: `PROS GNU Make: ${target}`,
           sh: false,
           env: env,
           errorMatch: [ gccErrorMatch ],
           warningMatch: [ gccWarningMatch ]
         })));
     }).catch(e => [ defaultTarget ]);
   }
 };
}
