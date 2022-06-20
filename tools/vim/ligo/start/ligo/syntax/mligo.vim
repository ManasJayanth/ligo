if exists("b:current_syntax")
    finish
endif

" string
syntax region string start="\"" end="\"" 
highlight link string String 

" comment
syntax match comment "\/\/.*$" 
syntax region comment start="(\*" end="\*)" 
highlight link comment Comment 

" typeproduct
syntax region typeproduct start="{" end="}" contained contains=identifier,typeannotation,semicolon 

" typeint
syntax match typeint "\<[0-9]+\>" contained 
highlight link typeint Number 

" typemodule
syntax match typemodule "\<\([A-Z][a-zA-Z0-9_$]*\)\." contained 
highlight link typemodule Identifier 

" typeparentheses
syntax region typeparentheses start="(" end=")" contained contains=typemodule,ofkeyword,identifierconstructor,typeoperator,typename,typevar,typeparentheses,typeint,typeproduct,string 

" typevar
syntax match typevar "'\<\([a-z_][a-zA-Z0-9_]*\)\>" contained 
highlight link typevar Type 

" typename
syntax match typename "\<\([a-z_][a-zA-Z0-9_]*\)\>" contained 
highlight link typename Type 

" typeoperator
syntax match typeoperator "\(->\|\.\|\*\||\)" contained 
highlight link typeoperator Operator 

" typeannotationlambda
syntax region typeannotationlambda matchgroup=typeannotationlambda_ start="\(:\)" end="\()\|=\|;\|}\|->\)\@!" contained contains=typemodule,ofkeyword,identifierconstructor,typeoperator,typename,typevar,typeparentheses,typeint,typeproduct,string 
highlight link typeannotationlambda_ Operator 

" typeannotation
syntax region typeannotation matchgroup=typeannotation_ start="\(:\)" end="\()\|=\|;\|}\)\@!" contains=typemodule,ofkeyword,identifierconstructor,typeoperator,typename,typevar,typeparentheses,typeint,typeproduct,string 
highlight link typeannotation_ Operator 

" typedefinition
syntax region typedefinition matchgroup=typedefinition_ start="\<\(type\)\>" end="\(^#\|\[%\|\<\(let\|in\|type\|end\|module\)\>\)\@!" contains=typemodule,ofkeyword,identifierconstructor,typeoperator,typename,typevar,typeparentheses,typeint,typeproduct,string 
highlight link typedefinition_ Keyword 

" identifierconstructor
syntax match identifierconstructor "\<\([A-Z][a-zA-Z0-9_$]*\)\>" 
highlight link identifierconstructor Label 

" identifier
syntax match identifier "\<[a-zA-Z$_][a-zA-Z0-9$_]*\>" contained 

" module
syntax match module_ "[a-z_][a-zA-Z0-9_$]*" contained 
highlight link module_ Identifier 
syntax match module "\<\([A-Z][a-zA-Z0-9_$]*\)\." nextgroup=module_ 
highlight link module Structure 

" lambda
syntax region lambda matchgroup=lambda_ start="\(fun\)\W" matchgroup=lambda__ end="\(->\)" contains=typeannotationlambda 
highlight link lambda_ Statement 
highlight link lambda__ Operator 

" ofkeyword
syntax match ofkeyword "\<\(of\)\>" contained 
highlight link ofkeyword Keyword 

" semicolon
syntax match semicolon ";" contained 

" operators
syntax match operators "\<\(::\|-\|+\|/\|mod\|land\|lor\|lxor\|lsl\|lsr\|&&\|||\|<\|>\|<>\|<=\|>=\)\>" 
highlight link operators Operator 

" numericliterals
syntax match numericliterals "\<[0-9]+\(n\|tz\|tez\|mutez\|\)\>" 
highlight link numericliterals Number 

" letbinding
syntax match letbinding__ "\<[a-zA-Z$_][a-zA-Z0-9$_]*\>" contained 
highlight link letbinding__ Statement 
syntax match letbinding_ "rec\W\|" contained nextgroup=letbinding__ 
highlight link letbinding_ StorageClass 
syntax match letbinding "\(let\)\W" nextgroup=letbinding_ 
highlight link letbinding Keyword 

" controlkeywords
syntax match controlkeywords "\<\(match\|with\|if\|then\|else\|assert\|failwith\|begin\|end\|in\)\>" 
highlight link controlkeywords Conditional 

" macro
syntax match macro "^\#[a-zA-Z]\+" 
highlight link macro PreProc 

" attribute
syntax match attribute "\[@.*\]" 
highlight link attribute PreProc 

let b:current_syntax = "mligo"