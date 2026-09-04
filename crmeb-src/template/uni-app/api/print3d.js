import request from '@/utils/request.js';

export function getPrintFileList(data) {
  return request.get('print/file/list', data || {});
}

export function getPrintFileInfo(id) {
  return request.get(`print/file/info/${id}`);
}

export function deletePrintFile(id) {
  return request.post(`print/file/delete/${id}`);
}

export function createPrintInquiry(data) {
  return request.post('print/inquiry/create', data);
}

export function getPrintInquiryList(data) {
  return request.get('print/inquiry/list', data || {});
}

export function getPrintInquiryDetail(id) {
  return request.get(`print/inquiry/detail/${id}`);
}

export function cancelPrintInquiry(id) {
  return request.post(`print/inquiry/cancel/${id}`);
}

export function confirmPrintInquiry(id) {
  return request.post(`print/inquiry/confirm/${id}`);
}
