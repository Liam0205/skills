---
title: "【Life on Python】一个简易的通讯录"
url: https://liam.page/2014/01/29/Py-Contacts/
date: 2014-01-29
categories: ["Algorithm and Computer Science"]
tags: ["Python", "Contact"]
---

提供了 add, remove, find, view 和 exit 几个命令行接口，意义很明确了，所以 help 选项没空写内容也无所谓了。第一次自己思考结构写的 Python 程序，有点小爽。XD

```python
import os
import cPickle as pickle
class Persion:
    '''\
    Describe a nature persion, his/her name, sex, and \
    age.'''
    def __init__(self, info):
        '''Initializes the person's data.'''
        self.name = info[0]
        self.sex  = info[1]
        self.age  = info[2]
        print '(Initializing %s)' % self.name
class Contact(Persion):
    '''\
    Describe a contact that is a nature persion, and \
    has his/her Tel., Addr., and Email.'''
    def __init__(self, info):
        Persion.__init__(self, info)
        self.tel   = info[3]
        self.addr  = info[4]
        self.email = info[5]
        self.info  = {self.name : (self.sex, self.age, self.tel, self.addr,\
            self.email)}
    def tell(self):
        print self.info

def command_line_interface():
    prompt = '--> '
    workingDict = {}
    if os.path.exists(r'.\Contact.data'):
        workingDict = pickle.load(open(r'.\Contact.data', 'r'))
    else:
        pass
    while True:
        getInput = raw_input(prompt)
        if getInput == 'exit':
            pickle.dump(workingDict, open(r'.\Contact.data', 'w'))
            break
        elif getInput == 'add':
            newContact = generate_new_contact(get_info_from_raw_input())
            workingDict[newContact.name] = newContact.info[newContact.name]
            pass
        elif getInput == 'find':
            pattern = raw_input('Enter the name:')
            if pattern in workingDict:
                print '-' * 45
                print 'Name:  %s\nSex:   %s\nAge:   %s\nTel.:  %s\nAddr.: %s\nEmail: %s' % (pattern, workingDict[pattern][0], workingDict[pattern][1], workingDict[pattern][2], workingDict[pattern][3], workingDict[pattern][4])
                print '-' * 45
            else:
                print 'Sorry, but "%s" is not in your contacts list.' % pattern
        elif getInput == 'remove':
            pattern = raw_input('Enter the name:')
            if pattern in workingDict:
                workingDict.pop(pattern)
                print 'Contact "%s" has been removed.' % pattern
            else:
                print 'Sorry, but "%s" is not in your contacts list.' % pattern
        elif getInput == 'view':
            population = len(workingDict)
            if population == 1:
                print 'There is only one contact:'
            elif population == 0:
                print 'There is no contact.'
                continue
            else:
                print 'There are %d contacts:' % population
            for name, info in workingDict.items():
                print '-' * 45
                print 'Name:  %s\nSex:   %s\nAge:   %s\nTel.:  %s\nAddr.: %s\nEmail: %s' % (name, info[0], info[1], info[2], info[3], info[4])
            pass
        elif getInput == 'help':
            print getInput
        else:
            exec(getInput)
            pass

def get_info_from_raw_input():
    info = []
    info.append(raw_input('Name:  '))
    info.append(raw_input('Sex:   '))
    info.append(raw_input('Age:   '))
    info.append(raw_input('Tel.:  '))
    info.append(raw_input('Addr.: '))
    info.append(raw_input('Email: '))
    return info
def generate_new_contact(info):
    return Contact(info)

if __name__ == '__main__':
    command_line_interface()
```